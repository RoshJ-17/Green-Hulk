import {
  Controller,
  Post,
  Body,
  UsePipes,
  ValidationPipe,
} from "@nestjs/common";
import { ApiTags, ApiOperation, ApiResponse } from "@nestjs/swagger";
import { AuthService } from "./auth.service";
import { RegisterDto } from "./dto/register.dto";
import { LoginDto } from "./dto/login.dto";
import { SendOtpDto } from "./dto/send-otp.dto";
import { VerifyOtpDto } from "./dto/verify-otp.dto";

@ApiTags("auth")
@Controller("auth")
export class AuthController {
  constructor(private readonly authService: AuthService) { }

  @Post("send-otp")
  @ApiOperation({ summary: "Send OTP to phone number" })
  @ApiResponse({ status: 201, description: "OTP sent (also printed to console)" })
  @UsePipes(new ValidationPipe())
  async sendOtp(@Body() sendOtpDto: SendOtpDto) {
    return this.authService.sendOtp(sendOtpDto);
  }

  @Post("verify-otp")
  @ApiOperation({ summary: "Verify OTP and return token" })
  @ApiResponse({ status: 200, description: "OTP verified correctly" })
  @UsePipes(new ValidationPipe())
  async verifyOtp(@Body() verifyOtpDto: VerifyOtpDto) {
    return this.authService.verifyOtp(verifyOtpDto);
  }

  @Post("register")
  @ApiOperation({ summary: "Register new user (phone + OTP + name)" })
  @ApiResponse({ status: 201, description: "User registered successfully" })
  @UsePipes(new ValidationPipe({ whitelist: true }))
  async register(@Body() registerDto: RegisterDto) {
    return this.authService.register(registerDto);
  }

  @Post("login")
  @ApiOperation({ summary: "Login via phone + OTP" })
  @ApiResponse({ status: 200, description: "User logged in" })
  @ApiResponse({ status: 401, description: "Invalid or expired OTP" })
  @UsePipes(new ValidationPipe())
  async login(@Body() loginDto: LoginDto) {
    return this.authService.login(loginDto);
  }
}
