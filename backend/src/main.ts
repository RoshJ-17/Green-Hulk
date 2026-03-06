import { NestFactory } from "@nestjs/core";
import { ValidationPipe, Logger } from "@nestjs/common";
import { SwaggerModule, DocumentBuilder } from "@nestjs/swagger";
import { NestExpressApplication } from "@nestjs/platform-express";
import { AppModule } from "./app.module";
import { join } from "path";
import { existsSync } from "fs";

async function bootstrap() {
  const logger = new Logger("Bootstrap");
  const app = await NestFactory.create<NestExpressApplication>(AppModule);

  // Enable CORS for mobile clients
  app.enableCors({
    origin: "*",
    methods: "GET,HEAD,PUT,PATCH,POST,DELETE",
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
