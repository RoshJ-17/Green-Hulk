import { Injectable, UnauthorizedException, ConflictException } from '@nestjs/common';
import { JwtService } from '@nestjs/jwt';
import { InjectRepository } from '@nestjs/typeorm';
import { Repository } from 'typeorm';
import { User } from '../database/entities/user.entity';
import * as bcrypt from 'bcrypt';
import { RegisterDto } from './dto/register.dto'; // We will create this
import { LoginDto } from './dto/login.dto';       // We will create this

@Injectable()
export class AuthService {
    constructor(
        @InjectRepository(User)
        private usersRepository: Repository<User>,
        private jwtService: JwtService,
    ) { }

    async register(registerDto: RegisterDto): Promise<{ token: string; user: any }> {
        const { email, password, fullName, phone } = registerDto;

        const existingUser = await this.usersRepository.findOne({ where: { email } });
        if (existingUser) {
            throw new ConflictException('Email already in use');
        }

        const salt = await bcrypt.genSalt();
        const passwordHash = await bcrypt.hash(password, salt);

        const user = this.usersRepository.create({
            email,
            passwordHash,
            fullName,
            phone,
        });

        await this.usersRepository.save(user);

        const payload = { sub: user.id, email: user.email };
        const token = this.jwtService.sign(payload);

        return {
            token,
            user: {
                id: user.id,
                email: user.email,
                fullName: user.fullName
            }
        };
    }

    async login(loginDto: LoginDto): Promise<{ token: string; user: any }> {
        const { email, password } = loginDto;
        const user = await this.usersRepository.findOne({ where: { email } });

        if (!user || !(await bcrypt.compare(password, user.passwordHash))) {
            throw new UnauthorizedException('Invalid credentials');
        }

        const payload = { sub: user.id, email: user.email };
        const token = this.jwtService.sign(payload);

        return {
            token,
            user: {
                id: user.id,
                email: user.email,
                fullName: user.fullName
            }
        };
    }
}
