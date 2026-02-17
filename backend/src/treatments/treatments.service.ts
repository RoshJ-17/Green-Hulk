import { Injectable, Logger, NotFoundException } from '@nestjs/common';
import * as fs from 'fs/promises';
import * as path from 'path';

/**
 * Treatments Service
 * Tasks 3.1.1 & 3.2.1: Treatment database and organic filtering
 */

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
    type: 'chemical' | 'organic';
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
    prevention: Array<{ action: string; importance: string }>;
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

@Injectable()
export class TreatmentsService {
    private readonly logger = new Logger(TreatmentsService.name);
    private readonly treatmentsPath: string;
    private treatmentsCache: Map<string, DiseaseData> = new Map();

    constructor() {
        // In development: __dirname = backend/dist/treatments
        // We need: backend/src/treatments/data/treatments.json
        // In production after build: dist/treatments should have the copied JSON

        if (__dirname.includes('dist')) {
            // Production/compiled - JSON should be copied to dist folder
            this.treatmentsPath = path.join(__dirname, 'data', 'treatments.json');
        } else {
            // Development - point to source folder
            this.treatmentsPath = path.join(__dirname, 'data', 'treatments.json');
        }

        // Fallback: Always try the source path in development
        const sourcePath = path.resolve(process.cwd(), 'src', 'treatments', 'data', 'treatments.json');
        this.treatmentsPath = sourcePath;

        this.loadTreatments();
    }

    /**
     * Load treatments database from JSON
     * Task 3.1.1: Treatment JSON database
     */
    private async loadTreatments(): Promise<void> {
        try {
            const fileContent = await fs.readFile(this.treatmentsPath, 'utf-8');
            const treatments = JSON.parse(fileContent);

            // Cache all disease treatments
            Object.keys(treatments).forEach((key) => {
                this.treatmentsCache.set(key, treatments[key]);
            });

            this.logger.log(`Loaded ${this.treatmentsCache.size} disease treatments`);
        } catch (error) {
            this.logger.error(`Failed to load treatments database: ${error.message}`);
        }
    }

    /**
     * Get treatments for a specific disease with optional filters
     * Task 3.1.1 & 3.2.1: Treatment retrieval with organic filtering
     */
    async getTreatments(
        diseaseKey: string,
        filters?: TreatmentFilters,
    ): Promise<DiseaseData> {
        this.logger.debug(`Getting treatments for ${diseaseKey}`);

        const diseaseData = this.treatmentsCache.get(diseaseKey);

        if (!diseaseData) {
            throw new NotFoundException(`No treatments found for disease: ${diseaseKey}`);
        }

        // Apply filters
        if (filters) {
            const filteredData = { ...diseaseData };

            // Filter organic only
            if (filters.organicOnly) {
                filteredData.treatments = diseaseData.treatments.filter(
                    (t) => t.is_organic,
                );
            }

            // Filter by effectiveness
            if (filters.minEffectiveness) {
                filteredData.treatments = filteredData.treatments.filter(
                    (t) => t.effectiveness >= filters.minEffectiveness!,
                );
            }

            return filteredData;
        }

        return diseaseData;
    }

    /**
     * Get only organic treatments for a disease
     * Task 3.2.1: Organic filter implementation
     */
    async getOrganicTreatments(diseaseKey: string): Promise<Treatment[]> {
        this.logger.debug(`Getting organic treatments for ${diseaseKey}`);

        const diseaseData = await this.getTreatments(diseaseKey);
        return diseaseData.treatments.filter((t) => t.is_organic);
    }

    /**
     * Get only chemical treatments for a disease
     */
    async getChemicalTreatments(diseaseKey: string): Promise<Treatment[]> {
        this.logger.debug(`Getting chemical treatments for ${diseaseKey}`);

        const diseaseData = await this.getTreatments(diseaseKey);
        return diseaseData.treatments.filter((t) => !t.is_organic);
    }

    /**
     * Get treatment steps with timeframe splitting
     * Task 3.1.1 & 14593: Split steps into "today" and "this week"
     */
    async getTreatmentSteps(
        diseaseKey: string,
        treatmentId: string,
        splitByTimeframe: boolean = false,
    ): Promise<{
        today?: TreatmentStep[];
        week?: TreatmentStep[];
        all?: TreatmentStep[];
    }> {
        const diseaseData = await this.getTreatments(diseaseKey);
        const treatment = diseaseData.treatments.find((t) => t.id === treatmentId);

        if (!treatment) {
            throw new NotFoundException(`Treatment ${treatmentId} not found`);
        }

        if (!splitByTimeframe) {
            return { all: treatment.steps };
        }

        // Task 14593: Divide steps into "What to do today" and "What to do in a week"
        const today = treatment.steps.filter((s) => s.timeframe === 'today');
        const week = treatment.steps.filter((s) => s.timeframe === 'week');

        return { today, week };
    }

    /**
     * Get home remedies for a disease
     * Task 14596: Research and add home remedies
     */
    async getHomeRemedies(diseaseKey: string): Promise<DiseaseData['home_remedies']> {
        this.logger.debug(`Getting home remedies for ${diseaseKey}`);

        const diseaseData = await this.getTreatments(diseaseKey);
        return diseaseData.home_remedies || [];
    }

    /**
     * Get prevention guidelines
     */
    async getPreventionTips(diseaseKey: string): Promise<DiseaseData['prevention']> {
        const diseaseData = await this.getTreatments(diseaseKey);
        return diseaseData.prevention || [];
    }

    /**
     * Get all available diseases
     */
    async getAllDiseases(): Promise<
        Array<{ key: string; name: string; crop: string }>
    > {
        const diseases: Array<{ key: string; name: string; crop: string }> = [];

        this.treatmentsCache.forEach((value, key) => {
            diseases.push({
                key,
                name: value.disease_name,
                crop: value.crop,
            });
        });

        return diseases;
    }

    /**
     * Search treatments by crop type
     */
    async getTreatmentsByCrop(crop: string): Promise<DiseaseData[]> {
        const treatments: DiseaseData[] = [];

        this.treatmentsCache.forEach((value) => {
            if (value.crop.toLowerCase() === crop.toLowerCase()) {
                treatments.push(value);
            }
        });

        return treatments;
    }

    /**
     * Get treatment by ID across all diseases
     */
    async getTreatmentById(treatmentId: string): Promise<Treatment | null> {
        for (const [, diseaseData] of this.treatmentsCache) {
            const treatment = diseaseData.treatments.find((t) => t.id === treatmentId);
            if (treatment) {
                return treatment;
            }
        }

        return null;
    }

    /**
     * Reload treatments from file
     */
    async reloadTreatments(): Promise<void> {
        this.treatmentsCache.clear();
        await this.loadTreatments();
        this.logger.log('Treatments database reloaded');
    }
}
