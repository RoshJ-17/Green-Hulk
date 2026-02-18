export interface TreatmentStep {
    order: number;
    action: string;
    duration: string;
    timeframe: string;
    dosage?: string;
    icon: string;
    details?: string;
}
export interface Treatment {
    id: string;
    type: "chemical" | "organic";
    is_organic: boolean;
    name: string;
    description?: string;
    effectiveness: number;
    cost_level?: string;
    steps: TreatmentStep[];
    safety_warnings: string[];
    organic_warning?: string;
}
export interface DiseaseData {
    disease_name: string;
    crop: string;
    description: string;
    treatments: Treatment[];
    prevention: Array<{
        action: string;
        importance: string;
    }>;
    home_remedies: Array<{
        name: string;
        ingredients: string[];
        preparation: string;
        frequency: string;
        effectiveness: number;
    }>;
}
export interface TreatmentFilters {
    organicOnly?: boolean;
    maxCostLevel?: string;
    minEffectiveness?: number;
}
export declare class TreatmentsService {
    private readonly logger;
    private readonly treatmentsPath;
    private treatmentsCache;
    constructor();
    private loadTreatments;
    getTreatments(diseaseKey: string, filters?: TreatmentFilters): Promise<DiseaseData>;
    getOrganicTreatments(diseaseKey: string): Promise<Treatment[]>;
    getChemicalTreatments(diseaseKey: string): Promise<Treatment[]>;
    getTreatmentSteps(diseaseKey: string, treatmentId: string, splitByTimeframe?: boolean): Promise<{
        today?: TreatmentStep[];
        week?: TreatmentStep[];
        all?: TreatmentStep[];
    }>;
    getHomeRemedies(diseaseKey: string): Promise<DiseaseData["home_remedies"]>;
    getPreventionTips(diseaseKey: string): Promise<DiseaseData["prevention"]>;
    getAllDiseases(): Promise<Array<{
        key: string;
        name: string;
        crop: string;
    }>>;
    getTreatmentsByCrop(crop: string): Promise<DiseaseData[]>;
    getTreatmentById(treatmentId: string): Promise<Treatment | null>;
    reloadTreatments(): Promise<void>;
}
