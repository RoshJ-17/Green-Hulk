process.env.NODE_ENV = 'test';
import { Test, TestingModule } from '@nestjs/testing';
import { INestApplication, ValidationPipe } from '@nestjs/common';
import request from 'supertest';
import { AppModule } from '../src/app.module';
import { getRepositoryToken } from '@nestjs/typeorm';
import { User } from '../src/database/entities/user.entity';
import { Repository } from 'typeorm';

/**
 * Part 2: Regression and E2E Tests
 * 
 * This suite covers:
 * 1. Regression Testing: Ensuring core logic (Filtering, Fallbacks) remains stable.
 * 2. E2E Testing: Simulating multi-step user journeys.
 */
describe('Backend Regression & E2E (e2e)', () => {
  let app: INestApplication;
  let userRepository: Repository<User>;

  beforeAll(async () => {
    const moduleFixture: TestingModule = await Test.createTestingModule({
      imports: [AppModule],
    }).compile();

    app = moduleFixture.createNestApplication();
    app.useGlobalPipes(new ValidationPipe());
    await app.init();

    userRepository = moduleFixture.get<Repository<User>>(getRepositoryToken(User));
  });

  afterAll(async () => {
    await app.close();
  });

  describe('Regression: Treatments Filtering & Search', () => {
    it('should filter organic treatments correctly', async () => {
      // Get all treatments for a disease
      const res = await request(app.getHttpServer())
        .get('/api/treatments/Apple___Apple_scab');
      
      expect(res.status).toBe(200);
      // DiseaseData structure: { treatments: Treatment[], ... }
      const allTreatments = res.body.treatments;

      // Get organic only (using correct query param name: organicOnly)
      const organicRes = await request(app.getHttpServer())
        .get('/api/treatments/Apple___Apple_scab?organicOnly=true');
      
      expect(organicRes.status).toBe(200);
      const organicTreatments = organicRes.body.treatments;

      // Verify organic list is a subset and actually organic
      expect(organicTreatments.length).toBeLessThanOrEqual(allTreatments.length);
      organicTreatments.forEach((t: any) => {
        expect(t.is_organic).toBe(true);
      });
    });

    it('should search treatments by crop name', async () => {
      // Correct endpoint: /api/treatments/crop/:cropType
      const res = await request(app.getHttpServer())
        .get('/api/treatments/crop/Apple');
      
      expect(res.status).toBe(200);
      expect(Array.isArray(res.body)).toBe(true);
      res.body.forEach((disease: any) => {
        // DiseaseData structure in array
        expect(disease.crop.toLowerCase()).toBe('apple');
      });
    });
  });

  describe('Regression: Localization Fallback', () => {
    it('should fall back to English for unsupported languages', async () => {
      const res = await request(app.getHttpServer())
        .get('/api/i18n/unsupported_lang');
      
      expect(res.status).toBe(200);
      // Verify it returns English content (has 'home' key)
      expect(res.body).toHaveProperty('home');
    });
  });

  describe('E2E: Authentication Flow', () => {
    const testPhone = '9876543210';
    const fullName = 'Test User';

    it('should complete full registration flow', async () => {
      // Clean up user if exists
      const existingUser = await userRepository.findOne({ where: { phone: testPhone } });
      if (existingUser) await userRepository.remove(existingUser);

      // 1. Send OTP
      await request(app.getHttpServer())
        .post('/auth/send-otp')
        .send({ phone: testPhone })
        .expect(201);

      // 2. "Receive" OTP from DB (Simulating SMS)
      const user = await userRepository.findOne({ where: { phone: testPhone } });
      expect(user).toBeDefined();
      expect(user?.otp).toBeDefined();
      const otp = user?.otp!;

      // 3. Register with the captured OTP
      const regRes = await request(app.getHttpServer())
        .post('/auth/register')
        .send({
          phone: testPhone,
          otp: otp,
          fullName: fullName
        });

      expect(regRes.status).toBe(201);
      // Property is accessToken (camelCase)
      expect(regRes.body).toHaveProperty('accessToken');
    });
  });

  describe('E2E: Search -> Diagnosis -> Treatment Flow', () => {
    it('should allow user to find treatments by searching for a crop', async () => {
      // 1. Search for Crop
      const searchRes = await request(app.getHttpServer())
        .get('/api/treatments/crop/Apple');
      
      expect(searchRes.status).toBe(200);
      const diseases = searchRes.body;
      expect(diseases.length).toBeGreaterThan(0);
      
      // 2. Pick the first disease (Apple Scab)
      const targetDisease = diseases[0];
      const diseaseKey = targetDisease.key || 'Apple___Apple_scab';

      // 3. Get detailed treatment plan
      const treatmentRes = await request(app.getHttpServer())
        .get(`/api/treatments/${diseaseKey}`);
      
      expect(treatmentRes.status).toBe(200);
      expect(treatmentRes.body.disease_name).toBeDefined();
      expect(Array.isArray(treatmentRes.body.treatments)).toBe(true);
      
      // 4. Verify treatment steps for the first treatment
      const firstTreatment = treatmentRes.body.treatments[0];
      expect(firstTreatment).toHaveProperty('id');
      expect(firstTreatment).toHaveProperty('steps');
      expect(firstTreatment.steps.length).toBeGreaterThan(0);
    });
  });
});
