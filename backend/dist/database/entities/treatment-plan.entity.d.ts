export declare class TreatmentPlan {
    id: number;
    diseaseId: string;
    diseaseName: string;
    cropType: string;
    steps: string;
    isOrganic: boolean;
    urgencyLevel: number;
    preventionTips?: string;
    safetyWarnings?: string;
    lastUpdated: Date;
}
