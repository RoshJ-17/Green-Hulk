import { Controller, Get } from '@nestjs/common';

@Controller('version')
export class VersionController {
  @Get()
  getLatestVersion() {
    return {
      latestVersion: '1.0.1',          // ← bump this every time you release
      downloadUrl: 'https://github.com/RoshJ-17/Green-Hulk/releases/latest/download/app-release.apk',
      forceUpdate: false,              // ← set true to force users to update
      releaseNotes: 'Bug fixes and improvements',
    };
  }
}
