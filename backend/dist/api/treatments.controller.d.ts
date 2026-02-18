import { TreatmentsService } from "@treatments/treatments.service";
export declare class TreatmentsController {
    private readonly treatmentsService;
    constructor(treatmentsService: TreatmentsService);
    getAllDiseases(): Promise<{
        key: string;
        name: string;
        crop: string;
    }[]>;
    getTreatments(diseaseKey: string, organicOnly?: boolean): Promise<import("@treatments/treatments.service").DiseaseData>;
    getOrganicTreatments(diseaseKey: string): Promise<{
        treatments: import("@treatments/treatments.service").Treatment[];
        count: number;
    }>;
    getChemicalTreatments(diseaseKey: string): Promise<{
        treatments: import("@treatments/treatments.service").Treatment[];
        count: number;
    }>;
    getTreatmentSteps(diseaseKey: string, treatmentId: string, split?: boolean): Promise<{
        today?: import("@treatments/treatments.service").TreatmentStep[];
        week?: import("@treatments/treatments.service").TreatmentStep[];
        all?: import("@treatments/treatments.service").TreatmentStep[];
    }>;
    getHomeRemedies(diseaseKey: string): Promise<{
        name: string;
        ingredients: string[];
        preparation: string;
        frequency: string;
        effectiveness: number;
    }[]>;
    getPreventionTips(diseaseKey: string): Promise<{
        action: string;
        importance: string;
    }[]>;
    getTreatmentsByCrop(crop: string): Promise<import("@treatments/treatments.service").DiseaseData[]>;
}
