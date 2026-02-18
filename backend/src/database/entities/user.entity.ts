import { Entity, Column, PrimaryGeneratedColumn, OneToMany, CreateDateColumn, UpdateDateColumn } from 'typeorm';
import { ScanRecord } from './scan-record.entity';

@Entity('users')
export class User {
    @PrimaryGeneratedColumn('uuid')
    id: string;

    @Column({ unique: true })
    email: string;

    @Column()
    passwordHash: string; // Store hashed password, never plain text

    @Column()
    fullName: string;

    @Column({ nullable: true })
    phone: string;

    @OneToMany(() => ScanRecord, (scan) => scan.user)
    scans: ScanRecord[];

    @CreateDateColumn()
    createdAt: Date;

    @UpdateDateColumn()
    updatedAt: Date;
}
