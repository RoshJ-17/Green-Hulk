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
import { VerifyOtpDto } from "./dto/verify-otp.dto";

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
  ) { }

  // ── OTP ─────────────────────────────────────────────────────────────────

  async sendOtp(dto: SendOtpDto): Promise<{ message: string }> {
    const { phone } = dto;
    const otp = Math.floor(100000 + Math.random() * 900000).toString();
    const expiresAt = new Date(Date.now() + 10 * 60 * 1000); // 10 min

    // Save to database
    let user = await this.userRepository.findOne({ where: { phone } });
    if (!user) {
      user = this.userRepository.create({ phone });
    }
    user.otp = otp;
    user.otpExpiresAt = expiresAt;
    await this.userRepository.save(user);

    // ── Always print to console ──────────────────────────────────────────
    this.logger.log(`OTP generated for ${phone}: ${otp}`);
    console.log('\n' + '='.repeat(55));
    console.log(`  📱  OTP for ${phone}  →  ${otp}  (valid 10 min)`);
    console.log('='.repeat(55) + '\n');

    // ── Fast2SMS Gateway (Production SMS) ──────────────
    const fast2SmsKey = process.env.FAST2SMS_API_KEY;
    if (fast2SmsKey && fast2SmsKey !== 'YOUR_FAST2SMS_API_KEY') {
      try {
        // Fast2SMS needs exactly 10 digits (no country code)
        // e.g. +919876543210 → 9876543210
        const digits = phone.replace(/\D/g, ''); // strip all non-digits
        const tenDigit = digits.length > 10 ? digits.slice(-10) : digits;

        const payload = {
          route: 'q',
          message: `Your CropCare OTP is ${otp}. Valid for 10 mins. Do not share.`,
          flash: 0,
          numbers: tenDigit,
        };

        this.logger.log(`Fast2SMS payload: ${JSON.stringify(payload)}`);

        const response = await axios.post(
          'https://www.fast2sms.com/dev/bulkV2',
          payload,
          {
            headers: {
              'authorization': fast2SmsKey,
              'Content-Type': 'application/json',
            },
          }
        );

        this.logger.log(`Fast2SMS response: ${JSON.stringify(response.data)}`);
        this.logger.log(`SMS dispatched to ${tenDigit} via Fast2SMS`);
      } catch (e: any) {
        const errData = e?.response?.data;
        this.logger.error(
          `Fast2SMS FAILED — ${JSON.stringify(errData) ?? e.message}`,
        );
        this.logger.log('OTP is still shown in console above for manual testing.');
      }
    } else {
      this.logger.warn(
        'FAST2SMS_API_KEY not configured — SMS skipped; OTP printed above.',
      );
    }

    return { message: `OTP sent to ${phone}` };
  }

  private async validateAndClearOtp(phone: string, otp: string): Promise<User> {
    const user = await this.userRepository.findOne({ where: { phone } });
    if (!user || user.otp !== otp || !user.otpExpiresAt || user.otpExpiresAt < new Date()) {
      throw new UnauthorizedException('Invalid or expired OTP');
    }
    user.otp = null;
    user.otpExpiresAt = null;
    return this.userRepository.save(user);
  }

  // ── Verify OTP ──────────────────────────────────────────────────────────

  async verifyOtp(
    dto: VerifyOtpDto,
  ): Promise<{ accessToken: string; isNewUser: boolean }> {
    const { phone, otp } = dto;
    const user = await this.validateAndClearOtp(phone, otp);

    const isNewUser = !user.fullName;
    if (isNewUser) {
      user.fullName = 'Farmer';
      await this.userRepository.save(user);
    }

    const payload = { sub: user.id, phone: user.phone };
    return { accessToken: this.jwtService.sign(payload), isNewUser };
  }

  // ── Register (new user) ──────────────────────────────────────────────────

  async register(dto: RegisterDto): Promise<{ accessToken: string }> {
    const { phone, otp, fullName, email } = dto;
    const user = await this.validateAndClearOtp(phone, otp);

    user.fullName = fullName;
    if (email) user.email = email;
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
    const isNewUser = !user || !user.fullName;
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
