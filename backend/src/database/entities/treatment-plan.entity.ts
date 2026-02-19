import {
  Entity,
  PrimaryGeneratedColumn,
  Column,
  UpdateDateColumn,
} from "typeorm";

@Entity("treatment_plans")
export class TreatmentPlan {
  @PrimaryGeneratedColumn()
  id: number;

  @Column({ unique: true })
  diseaseId: string; // e.g., "Tomato___Early_blight"

  @Column()
  diseaseName: string; // e.g., "Early_blight"

  @Column()
  cropType: string; // e.g., "Tomato"

  @Column("text")
  steps: string; // JSON array of treatment steps

  @Column({ default: true })
  isOrganic: boolean;

  @Column("int")
  urgencyLevel: number; // 1=Low, 2=Medium, 3=High

  @Column("text", { nullable: true })
  preventionTips?: string; // JSON array

  @Column("text", { nullable: true })
  safetyWarnings?: string; // JSON array

  @UpdateDateColumn()
  lastUpdated: Date;
}
