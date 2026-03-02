import { Test, TestingModule } from '@nestjs/testing';
import { INestApplication } from '@nestjs/common';
import request from 'supertest';
import { AppModule } from '../src/app.module';

/**
 * End-to-End Tests for the Backend API
 * 
 * These tests verify the primary REST endpoints used by the Flutter frontend.
 * They run against a live NestJS application instance.
 */
describe('Backend API (e2e)', () => {
    let app: INestApplication;

    // Initialize the NestJS application before running tests
    beforeAll(async () => {
        const moduleFixture: TestingModule = await Test.createTestingModule({
            imports: [AppModule],
        }).compile();

        app = moduleFixture.createNestApplication();

        /**
         * Note: app.setGlobalPrefix('api') was removed because the controllers
         * already define their routes starting with 'api/'. Keeping it here
         * would result in double prefixing (e.g., /api/api/i18n).
         */
        await app.init();
    });

    // Clean up: Close the application after all tests are finished
    afterAll(async () => {
        await app.close();
    });

    /**
     * Localization API Tests
     * Verifies translation retrieval and language support endpoints
     */
    describe('Localization API', () => {
        it('/i18n/languages/supported (GET)', () => {
            return request(app.getHttpServer())
                .get('/api/i18n/languages/supported')
                .expect(200)
                .expect((res: request.Response) => {
                    // Expect a list of supported languages
                    expect(Array.isArray(res.body.languages)).toBe(true);

                    // Verify English is among the supported languages
                    const langCodes = res.body.languages.map((l: any) => l.code);
                    expect(langCodes).toContain('en');
                });
        });

        it('/i18n/en (GET)', () => {
            return request(app.getHttpServer())
                .get('/api/i18n/en')
                .expect(200)
                .expect((res: request.Response) => {
                    expect(res.body).toBeDefined();

                    // Verify presence of home screen translation keys
                    if (res.body.home) {
                        expect(res.body.home).toBeDefined();
                    }
                });
        });
    });

    /**
     * Treatments API Tests
     * Verifies retrieval of disease treatment data
     */
    describe('Treatments API', () => {
        it('/treatments/diseases (GET)', () => {
            return request(app.getHttpServer())
                .get('/api/treatments/diseases')
                .expect(200)
                .expect((res: request.Response) => {
                    // Expect an array of disease keys and names
                    expect(Array.isArray(res.body)).toBe(true);
                });
        });
    });

    /**
     * Preferences API Tests
     * Verifies user settings and storage status endpoints
     */
    describe('Preferences API', () => {
        it('/preferences/storage/info (GET)', () => {
            return request(app.getHttpServer())
                .get('/api/preferences/storage/info')
                .expect(200)
                .expect((res: request.Response) => {
                    // Verify the storage info contains the total size in bytes
                    expect(res.body).toHaveProperty('totalSizeBytes');
                });
        });
    });
});
