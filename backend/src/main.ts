import { NestFactory } from "@nestjs/core";
import { ValidationPipe, Logger } from "@nestjs/common";
import { SwaggerModule, DocumentBuilder } from "@nestjs/swagger";
import { NestExpressApplication } from "@nestjs/platform-express";
import { AppModule } from "./app.module";
import { join } from "path";
import { existsSync } from "fs";

async function bootstrap() {
  const logger = new Logger("Bootstrap");
  // abortOnError: false — app continues starting even if a module (e.g. TypeORM/DB)
  // fails to initialise. DB-dependent endpoints will 503; diagnosis still works.
  const app = await NestFactory.create<NestExpressApplication>(AppModule, {
    abortOnError: false,
  });

  // Enable CORS for mobile + web clients.
  //
  // Problem: Flutter web dev server runs on a random port (e.g. localhost:52419).
  // A static allow-list can never cover every such port, so we use a function
  // that accepts ANY localhost / 127.0.0.1 origin in development and restricts
  // to an explicit FRONTEND_URL list in production.
  const isDev = (process.env.NODE_ENV ?? 'development') !== 'production';
  const explicitOrigins = (process.env.FRONTEND_URL ?? '')
    .split(',').map((o) => o.trim()).filter(Boolean);

  app.enableCors({
    origin: (origin: string | undefined, callback: (err: Error | null, allow?: boolean) => void) => {
      // Allow same-origin requests and non-browser clients (mobile / curl / Postman)
      if (!origin) return callback(null, true);

      // In dev: allow all localhost / 127.0.0.1 origins regardless of port
      if (isDev && /^https?:\/\/(localhost|127\.0\.0\.1)(:\d+)?$/.test(origin)) {
        return callback(null, true);
      }

      // In production (or non-localhost origins): check explicit allow-list
      if (explicitOrigins.includes(origin)) return callback(null, true);

      callback(new Error(`CORS: origin '${origin}' not allowed`));
    },
    methods: 'GET,HEAD,PUT,PATCH,POST,DELETE',
    credentials: true,
  });

  // Global validation pipe
  app.useGlobalPipes(
    new ValidationPipe({
      whitelist: true,
      forbidNonWhitelisted: true,
      transform: true,
    }),
  );

  // Swagger documentation
  const config = new DocumentBuilder()
    .setTitle("Plant Disease Detection API")
    .setDescription(
      "Production-ready backend for plant disease detection with offline-first architecture",
    )
    .setVersion("1.0")
    .addTag("diagnosis", "Disease diagnosis endpoints")
    .addTag("scans", "Scan history management")
    .build();

  const document = SwaggerModule.createDocument(app, config);
  SwaggerModule.setup("api/docs", app, document);

  // ── Serve Flutter Web Frontend ───────────────────────────────────────────
  // On Railway the Docker image includes the Flutter web build in /app/public
  // (placed there by CI before docker build runs).
  const publicDir = join(__dirname, "..", "public");
  if (existsSync(publicDir)) {
    app.useStaticAssets(publicDir, { prefix: "/" });
    logger.log(`Serving Flutter web frontend from ${publicDir}`);

    const httpAdapter = app.getHttpAdapter();
    httpAdapter.get("/", (_req: unknown, res: { sendFile: (p: string) => void }) => {
      res.sendFile(join(publicDir, "index.html"));
    });
  } else {
    // Local dev — no static build present, return JSON health check
    const httpAdapter = app.getHttpAdapter();
    httpAdapter.get("/", (_req: unknown, res: { json: (data: object) => void }) => {
      res.json({
        status: "ok",
        message: "Green-Hulk Plant Disease Detection API",
        version: "1.0",
        docs: "/api/docs",
      });
    });
  }
  // ────────────────────────────────────────────────────────────────────────

  const port = process.env.PORT || 3000;
  await app.listen(port);

  logger.log(`Application is running on: http://localhost:${port}`);
  logger.log(`Swagger documentation: http://localhost:${port}/api/docs`);
}

bootstrap();
