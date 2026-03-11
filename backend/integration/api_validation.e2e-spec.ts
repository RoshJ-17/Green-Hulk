process.env.NODE_ENV = 'test';
import { Test, TestingModule } from '@nestjs/testing';
import { INestApplication, ValidationPipe } from '@nestjs/common';
import request from 'supertest';
import { AppModule } from '../src/app.module';

/**
 * Part 1: API and Validation Tests
 * 
 * This suite covers:
 * 1. API Testing: Verifying endpoint availability and response structure.
 * 2. Validation Testing: Ensuring the backend correctly rejects malformed inputs.
 */
describe('Backend API & Validation (e2e)', () => {
  let app: INestApplication;

  beforeAll(async () => {
    const moduleFixture: TestingModule = await Test.createTestingModule({
      imports: [
        AppModule,
      ],
    }).compile();

    app = moduleFixture.createNestApplication();

    app = moduleFixture.createNestApplication();
    
    // Crucial: Use the same validation pipe as the main app
    app.useGlobalPipes(new ValidationPipe({
      whitelist: true,
      forbidNonWhitelisted: true,
      transform: true,
    }));

    await app.init();
  });

  afterAll(async () => {
    await app.close();
  });

  describe('API Endpoints (GET)', () => {
    it('/api/i18n/languages/supported (GET) - Should return list of languages', () => {
      return request(app.getHttpServer())
        .get('/api/i18n/languages/supported')
        .expect(200)
        .expect((res) => {
          expect(res.body).toHaveProperty('languages');
          expect(Array.isArray(res.body.languages)).toBe(true);
        });
    });

    it('/api/i18n/en (GET) - Should return English translations', () => {
      return request(app.getHttpServer())
        .get('/api/i18n/en')
        .expect(200)
        .expect((res) => {
          expect(res.body).toBeDefined();
          // We expect some top-level keys like 'common' or 'home'
          expect(Object.keys(res.body).length).toBeGreaterThan(0);
        });
    });

    it('/api/treatments/diseases (GET) - Should return list of diseases', () => {
      return request(app.getHttpServer())
        .get('/api/treatments/diseases')
        .expect(200)
        .expect((res) => {
          expect(Array.isArray(res.body)).toBe(true);
          if (res.body.length > 0) {
            expect(res.body[0]).toHaveProperty('key');
            expect(res.body[0]).toHaveProperty('name');
          }
        });
    });
  });

  describe('Validation (POST)', () => {
    describe('/auth/send-otp', () => {
      it('should fail with a 9-digit phone number', () => {
        return request(app.getHttpServer())
          .post('/auth/send-otp')
          .send({ phone: '123456789' })
          .expect(400)
          .expect((res) => {
            expect(res.body.message).toContain('Phone must be exactly 10 digits');
          });
      });

      it('should fail with a phone number containing letters', () => {
        return request(app.getHttpServer())
          .post('/auth/send-otp')
          .send({ phone: '987654321a' })
          .expect(400);
      });
    });

    describe('/auth/register', () => {
      it('should fail when fullName is missing', () => {
        return request(app.getHttpServer())
          .post('/auth/register')
          .send({
            phone: '9876543210',
            otp: '123456',
            email: 'test@example.com'
          })
          .expect(400);
      });

      it('should fail when OTP is wrong length (5 digits)', () => {
        return request(app.getHttpServer())
          .post('/auth/register')
          .send({
            phone: '9876543210',
            otp: '12345',
            fullName: 'Test User'
          })
          .expect(400);
      });
    });
  });
});
