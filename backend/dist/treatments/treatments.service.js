"use strict";
var __createBinding = (this && this.__createBinding) || (Object.create ? (function(o, m, k, k2) {
    if (k2 === undefined) k2 = k;
    var desc = Object.getOwnPropertyDescriptor(m, k);
    if (!desc || ("get" in desc ? !m.__esModule : desc.writable || desc.configurable)) {
      desc = { enumerable: true, get: function() { return m[k]; } };
    }
    Object.defineProperty(o, k2, desc);
}) : (function(o, m, k, k2) {
    if (k2 === undefined) k2 = k;
    o[k2] = m[k];
}));
var __setModuleDefault = (this && this.__setModuleDefault) || (Object.create ? (function(o, v) {
    Object.defineProperty(o, "default", { enumerable: true, value: v });
}) : function(o, v) {
    o["default"] = v;
});
var __decorate = (this && this.__decorate) || function (decorators, target, key, desc) {
    var c = arguments.length, r = c < 3 ? target : desc === null ? desc = Object.getOwnPropertyDescriptor(target, key) : desc, d;
    if (typeof Reflect === "object" && typeof Reflect.decorate === "function") r = Reflect.decorate(decorators, target, key, desc);
    else for (var i = decorators.length - 1; i >= 0; i--) if (d = decorators[i]) r = (c < 3 ? d(r) : c > 3 ? d(target, key, r) : d(target, key)) || r;
    return c > 3 && r && Object.defineProperty(target, key, r), r;
};
var __importStar = (this && this.__importStar) || (function () {
    var ownKeys = function(o) {
        ownKeys = Object.getOwnPropertyNames || function (o) {
            var ar = [];
            for (var k in o) if (Object.prototype.hasOwnProperty.call(o, k)) ar[ar.length] = k;
            return ar;
        };
        return ownKeys(o);
    };
    return function (mod) {
        if (mod && mod.__esModule) return mod;
        var result = {};
        if (mod != null) for (var k = ownKeys(mod), i = 0; i < k.length; i++) if (k[i] !== "default") __createBinding(result, mod, k[i]);
        __setModuleDefault(result, mod);
        return result;
    };
})();
var __metadata = (this && this.__metadata) || function (k, v) {
    if (typeof Reflect === "object" && typeof Reflect.metadata === "function") return Reflect.metadata(k, v);
};
var TreatmentsService_1;
Object.defineProperty(exports, "__esModule", { value: true });
exports.TreatmentsService = void 0;
const common_1 = require("@nestjs/common");
const fs = __importStar(require("fs/promises"));
const path = __importStar(require("path"));
let TreatmentsService = TreatmentsService_1 = class TreatmentsService {
    constructor() {
        this.logger = new common_1.Logger(TreatmentsService_1.name);
        this.treatmentsCache = new Map();
        if (__dirname.includes('dist')) {
            this.treatmentsPath = path.join(__dirname, 'data', 'treatments.json');
        }
        else {
            this.treatmentsPath = path.join(__dirname, 'data', 'treatments.json');
        }
        const sourcePath = path.resolve(process.cwd(), 'src', 'treatments', 'data', 'treatments.json');
        this.treatmentsPath = sourcePath;
        this.loadTreatments();
    }
    async loadTreatments() {
        try {
            const fileContent = await fs.readFile(this.treatmentsPath, 'utf-8');
            const treatments = JSON.parse(fileContent);
            Object.keys(treatments).forEach((key) => {
                this.treatmentsCache.set(key, treatments[key]);
            });
            this.logger.log(`Loaded ${this.treatmentsCache.size} disease treatments`);
        }
        catch (error) {
            this.logger.error(`Failed to load treatments database: ${error.message}`);
        }
    }
    async getTreatments(diseaseKey, filters) {
        this.logger.debug(`Getting treatments for ${diseaseKey}`);
        const diseaseData = this.treatmentsCache.get(diseaseKey);
        if (!diseaseData) {
            throw new common_1.NotFoundException(`No treatments found for disease: ${diseaseKey}`);
        }
        if (filters) {
            const filteredData = { ...diseaseData };
            if (filters.organicOnly) {
                filteredData.treatments = diseaseData.treatments.filter((t) => t.is_organic);
            }
            if (filters.minEffectiveness) {
                filteredData.treatments = filteredData.treatments.filter((t) => t.effectiveness >= filters.minEffectiveness);
            }
            return filteredData;
        }
        return diseaseData;
    }
    async getOrganicTreatments(diseaseKey) {
        this.logger.debug(`Getting organic treatments for ${diseaseKey}`);
        const diseaseData = await this.getTreatments(diseaseKey);
        return diseaseData.treatments.filter((t) => t.is_organic);
    }
    async getChemicalTreatments(diseaseKey) {
        this.logger.debug(`Getting chemical treatments for ${diseaseKey}`);
        const diseaseData = await this.getTreatments(diseaseKey);
        return diseaseData.treatments.filter((t) => !t.is_organic);
    }
    async getTreatmentSteps(diseaseKey, treatmentId, splitByTimeframe = false) {
        const diseaseData = await this.getTreatments(diseaseKey);
        const treatment = diseaseData.treatments.find((t) => t.id === treatmentId);
        if (!treatment) {
            throw new common_1.NotFoundException(`Treatment ${treatmentId} not found`);
        }
        if (!splitByTimeframe) {
            return { all: treatment.steps };
        }
        const today = treatment.steps.filter((s) => s.timeframe === 'today');
        const week = treatment.steps.filter((s) => s.timeframe === 'week');
        return { today, week };
    }
    async getHomeRemedies(diseaseKey) {
        this.logger.debug(`Getting home remedies for ${diseaseKey}`);
        const diseaseData = await this.getTreatments(diseaseKey);
        return diseaseData.home_remedies || [];
    }
    async getPreventionTips(diseaseKey) {
        const diseaseData = await this.getTreatments(diseaseKey);
        return diseaseData.prevention || [];
    }
    async getAllDiseases() {
        const diseases = [];
        this.treatmentsCache.forEach((value, key) => {
            diseases.push({
                key,
                name: value.disease_name,
                crop: value.crop,
            });
        });
        return diseases;
    }
    async getTreatmentsByCrop(crop) {
        const treatments = [];
        this.treatmentsCache.forEach((value) => {
            if (value.crop.toLowerCase() === crop.toLowerCase()) {
                treatments.push(value);
            }
        });
        return treatments;
    }
    async getTreatmentById(treatmentId) {
        for (const [, diseaseData] of this.treatmentsCache) {
            const treatment = diseaseData.treatments.find((t) => t.id === treatmentId);
            if (treatment) {
                return treatment;
            }
        }
        return null;
    }
    async reloadTreatments() {
        this.treatmentsCache.clear();
        await this.loadTreatments();
        this.logger.log('Treatments database reloaded');
    }
};
exports.TreatmentsService = TreatmentsService;
exports.TreatmentsService = TreatmentsService = TreatmentsService_1 = __decorate([
    (0, common_1.Injectable)(),
    __metadata("design:paramtypes", [])
], TreatmentsService);
//# sourceMappingURL=treatments.service.js.map