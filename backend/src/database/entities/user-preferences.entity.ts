import {
  Entity,
  PrimaryGeneratedColumn,
  Column,
  UpdateDateColumn,
} from "typeorm";

@Entity("user_preferences")
export class UserPreferences {
  @PrimaryGeneratedColumn()
  id: number;

  @Column({ nullable: true })
  preferredLanguage?: string;

  @Column({ nullable: true })
  defaultCrop?: string;

  @Column({ default: true })
  preferOrganicTreatments: boolean;

  @UpdateDateColumn()
  lastModified: Date;
}
