import {
  Injectable,
  Logger,
  UnauthorizedException,
} from "@nestjs/common";
import { JwtService } from "@nestjs/jwt";
import { InjectRepository } from "@nestjs/typeorm";
import { Repository } from "typeorm";
import axios from "axios";
import { User } from "../database/entities/user.entity";
import { RegisterDto } from "./dto/register.dto";
import { LoginDto } from "./dto/login.dto";
import { SendOtpDto } from "./dto/send-otp.dto";

interface OtpEntry { otp: string; expiresAt: Date; }

@Injectable()
export class AuthService {
  private readonly logger = new Logger(AuthService.name);
  /** In-memory OTP store: phone → { otp, expiresAt } */
  private readonly otpStore = new Map<string, OtpEntry>();

  constructor(
    @InjectRepository(User)
    private readonly userRepository: Repository<User>,
    private readonly jwtService: JwtService,
  ) {}

  // ── OTP ─────────────────────────────────────────────────────────────────

  async sendOtp(dto: SendOtpDto): Promise<{ message: string }> {
    const { phone } = dto;
    const otp = Math.floor(100000 + Math.random() * 900000).toString();
    const expiresAt = new Date(Date.now() + 10 * 60 * 1000); // 10 min

    this.otpStore.set(phone, { otp, expiresAt });

    // ── Always print to console ──────────────────────────────────────────
    this.logger.log(`OTP generated for ${phone}: ${otp}`);
    console.log('\n' + '='.repeat(55));
    console.log(`  📱  OTP for ${phone}  →  ${otp}  (valid 10 min)`);
    console.log('='.repeat(55) + '\n');

    // ── Fast2SMS (optional – only if API key is configured) ──────────────
    const apiKey = process.env.FAST2SMS_API_KEY;
    if (apiKey && apiKey !== 'YOUR_FAST2SMS_API_KEY_HERE') {
      try {
        await axios.get('https://www.fast2sms.com/dev/bulkV2', {
          headers: { authorization: apiKey },
          params: {
            route: 'q',
            message: `Your CropCare OTP is ${otp}. Valid for 10 mins. Do not share.`,
            numbers: phone,
          },
        });
        this.logger.log(`SMS dispatched to ${phone} via Fast2SMS`);
      } catch (e: any) {
        this.logger.warn(
          `Fast2SMS error (OTP shown in console): ${
            e?.response?.data?.message ?? e.message
          }`,
        );
      }
    } else {
      this.logger.warn(
        'FAST2SMS_API_KEY not configured — SMS skipped; OTP printed above.',
      );
    }

    return { message: `OTP sent to ${phone}` };
  }

  private consumeOtp(phone: string, otp: string): boolean {
    const stored = this.otpStore.get(phone);
    if (!stored || stored.otp !== otp || stored.expiresAt < new Date()) {
      this.otpStore.delete(phone);
      return false;
    }
    this.otpStore.delete(phone);
    return true;
  }

  // ── Register (new user) ──────────────────────────────────────────────────

  async register(dto: RegisterDto): Promise<{ accessToken: string }> {
    const { phone, otp, fullName, email } = dto;

    if (!this.consumeOtp(phone, otp)) {
      throw new UnauthorizedException('Invalid or expired OTP');
    }

    let user = await this.userRepository.findOne({ where: { phone } });
    if (user) {
      user.fullName = fullName;
      if (email) user.email = email;
    } else {
      user = this.userRepository.create({
        phone,
        fullName,
        email: email ?? null,
        passwordHash: null,
      });
    }
    await this.userRepository.save(user);

    const payload = { sub: user.id, phone: user.phone };
    return { accessToken: this.jwtService.sign(payload) };
  }

  // ── Login (returning user) ───────────────────────────────────────────────

  async login(
    dto: LoginDto,
  ): Promise<{ accessToken: string; isNewUser: boolean }> {
    const { phone } = dto;

    let user = await this.userRepository.findOne({ where: { phone } });
    const isNewUser = !user;
    if (!user) {
      user = this.userRepository.create({
        phone,
        fullName: 'Farmer',
        passwordHash: null,
        email: null,
      });
      await this.userRepository.save(user);
    }

    const payload = { sub: user.id, phone: user.phone };
    return { accessToken: this.jwtService.sign(payload), isNewUser };
  }
}
