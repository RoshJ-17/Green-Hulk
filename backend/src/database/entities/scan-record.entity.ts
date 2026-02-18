import {
    Entity,
    PrimaryGeneratedColumn,
    Column,
    CreateDateColumn,
    ManyToOne,
} from 'typeorm';
import { User } from './user.entity';

@Entity('scan_records')
export class ScanRecord {
    @PrimaryGeneratedColumn()
    id: number;

    @CreateDateColumn()
    timestamp: Date;

    @Column()
    cropType: string;

    @Column()
    imagePath: string;

    @Column()
    diseaseName: string;

    @Column()
    fullLabel: string;

    @Column('float')
    confidence: number;

    @Column()
    severity: string;

    @Column('float', { nullable: true })
    affectedAreaPercentage?: number;

    @Column({ nullable: true })
    heatmapPath?: string;

    @Column('float', { nullable: true })
    latitude?: number;

    @Column('float', { nullable: true })
    longitude?: number;

    @Column({ default: false })
    isSynced: boolean;

    @Column({ type: 'datetime', nullable: true })
    lastSyncAttempt?: Date;

    @Column('float', { nullable: true })
    imageBlurScore?: number;

    @Column('float', { nullable: true })
    imageBrightness?: number;

    @Column({ default: false })
    hadQualityWarnings: boolean;

    @Column({ nullable: true })
    userId: string;

    @ManyToOne(() => User, (user) => user.scans)
    user: User;
}
