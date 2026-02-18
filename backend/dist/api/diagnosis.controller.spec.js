"use strict";
Object.defineProperty(exports, "__esModule", { value: true });
const testing_1 = require("@nestjs/testing");
const common_1 = require("@nestjs/common");
const typeorm_1 = require("@nestjs/typeorm");
const diagnosis_controller_1 = require("./diagnosis.controller");
const diagnosis_service_1 = require("../diagnosis/diagnosis.service");
const supported_classes_service_1 = require("../validators/supported-classes.service");
const label_loader_service_1 = require("../ml/label-loader.service");
const scan_record_entity_1 = require("../database/entities/scan-record.entity");
describe('DiagnosisController', () => {
    let controller;
    let diagnosisService;
    let supportedClasses;
    const mockFile = {
        fieldname: 'image',
        originalname: 'test-plant.jpg',
        encoding: '7bit',
        mimetype: 'image/jpeg',
        size: 50000,
        buffer: Buffer.from('fake image data'),
        stream: null,
        destination: '',
        filename: '',
        path: '',
    };
    beforeEach(async () => {
        const module = await testing_1.Test.createTestingModule({
            controllers: [diagnosis_controller_1.DiagnosisController],
            providers: [
                {
                    provide: diagnosis_service_1.DiagnosisService,
                    useValue: {
                        diagnose: jest.fn(),
                    },
                },
                {
                    provide: supported_classes_service_1.SupportedClassesService,
                    useValue: {
                        isCropSupported: jest.fn(),
                        getSupportedCrops: jest.fn().mockReturnValue(['Tomato', 'Potato', 'Corn']),
                    },
                },
                {
                    provide: label_loader_service_1.LabelLoaderService,
                    useValue: {
                        getLabel: jest.fn(),
                    },
                },
                {
                    provide: (0, typeorm_1.getRepositoryToken)(scan_record_entity_1.ScanRecord),
                    useValue: {
                        save: jest.fn().mockResolvedValue({}),
                        find: jest.fn(),
                        findOne: jest.fn(),
                    },
                },
            ],
        }).compile();
        controller = module.get(diagnosis_controller_1.DiagnosisController);
        diagnosisService = module.get(diagnosis_service_1.DiagnosisService);
        supportedClasses = module.get(supported_classes_service_1.SupportedClassesService);
    });
    it('should be defined', () => {
        expect(controller).toBeDefined();
    });
    it('should successfully diagnose with valid input', async () => {
        const dto = { selectedCrop: 'Tomato' };
        supportedClasses.isCropSupported.mockReturnValue(true);
        diagnosisService.diagnose.mockResolvedValue({
            type: 'success',
            disease: 'Tomato___Late_blight',
            confidence: 0.92,
            severity: 'high',
            cropType: 'Tomato',
        });
        const result = await controller.diagnose(mockFile, dto);
        expect(result.type).toBe('success');
        expect(diagnosisService.diagnose).toHaveBeenCalledWith(mockFile.buffer, 'Tomato');
    });
    it('should throw BadRequestException when file is missing', async () => {
        const dto = { selectedCrop: 'Tomato' };
        await expect(controller.diagnose(null, dto)).rejects.toThrow(common_1.BadRequestException);
    });
    it('should throw BadRequestException for unsupported crop', async () => {
        const dto = { selectedCrop: 'Banana' };
        supportedClasses.isCropSupported.mockReturnValue(false);
        await expect(controller.diagnose(mockFile, dto)).rejects.toThrow(common_1.BadRequestException);
    });
    it('should handle diagnosis errors', async () => {
        const dto = { selectedCrop: 'Tomato' };
        supportedClasses.isCropSupported.mockReturnValue(true);
        diagnosisService.diagnose.mockResolvedValue({
            type: 'error',
            message: 'Poor image quality',
        });
        const result = await controller.diagnose(mockFile, dto);
        expect(result.type).toBe('error');
        expect(result.message).toBe('Poor image quality');
    });
});
//# sourceMappingURL=diagnosis.controller.spec.js.map