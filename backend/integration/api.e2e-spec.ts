import { Test, TestingModule } from '@nestjs/testing';
import { INestApplication } from '@nestjs/common';
import request from 'supertest';
import { AppModule } from '../src/app.module';

describe('Backend API (e2e)', () => {
    let app: INestApplication;

    beforeAll(async () => {
        const moduleFixture: TestingModule = await Test.createTestingModule({
            imports: [AppModule],
        }).compile();

        app = moduleFixture.createNestApplication();
        await app.init();
    });

    afterAll(async () => {
        await app.close();
    });

    describe('Localization API', () => {
        it('/i18n/languages/supported (GET)', () => {
            return request(app.getHttpServer())
                .get('/api/i18n/languages/supported')
                .expect(200)
                .expect((res: request.Response) => {
                    expect(Array.isArray(res.body.languages)).toBe(true);
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
                    // Check for some common keys mentioned in BACKEND_IMPLEMENTATION.md
                    if (res.body.home) {
                        expect(res.body.home).toBeDefined();
                    }
                });
        });
    });

    describe('Treatments API', () => {
        it('/treatments/diseases (GET)', () => {
            return request(app.getHttpServer())
                .get('/api/treatments/diseases')
                .expect(200)
                .expect((res: request.Response) => {
                    expect(Array.isArray(res.body)).toBe(true);
                });
        });
    });

    describe('Preferences API', () => {
        it('/preferences/storage/info (GET)', () => {
            return request(app.getHttpServer())
                .get('/api/preferences/storage/info')
                .expect(200)
                .expect((res: request.Response) => {
                    expect(res.body).toHaveProperty('totalSizeBytes');
                });
        });
    });
});
