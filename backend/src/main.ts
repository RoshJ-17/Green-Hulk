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

  // Serve Flutter web static files if they exist
  const webDistPath = join(__dirname, "..", "web");
  if (existsSync(webDistPath)) {
    app.useStaticAssets(webDistPath);

    // For any non-API route, serve Flutter's index.html (client-side routing)
    const httpAdapter = app.getHttpAdapter();
    httpAdapter.get(/^(?!\/api).*$/, (_req: unknown, res: { sendFile: (path: string) => void }) => {
      res.sendFile(join(webDistPath, "index.html"));
    });

    logger.log(`Serving Flutter web from: ${webDistPath}`);
  } else {
    // Fallback health check if no Flutter build present
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

  const port = process.env.PORT || 3000;
  await app.listen(port);

  logger.log(`Application is running on: http://localhost:${port}`);
  logger.log(`Swagger documentation: http://localhost:${port}/api/docs`);
}

bootstrap();
