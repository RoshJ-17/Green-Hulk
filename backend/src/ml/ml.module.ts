import { Module } from '@nestjs/common';
import { ModelLoaderService } from './model-loader.service';
import { LabelLoaderService } from './label-loader.service';

@Module({
    providers: [ModelLoaderService, LabelLoaderService],
    exports: [ModelLoaderService, LabelLoaderService],
})
export class MlModule { }
