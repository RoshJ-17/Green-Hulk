import { IsString, IsNotEmpty, IsOptional } from 'class-validator';
import { ApiProperty } from '@nestjs/swagger';

export class DiagnoseRequestDto {
    @ApiProperty({
        description: 'Selected crop type',
        example: 'Tomato',
        enum: [
            'Apple',
            'Blueberry',
            'Cherry',
            'Corn',
            'Grape',
            'Orange',
            'Peach',
            'Pepper',
            'Potato',
            'Raspberry',
            'Soybean',
            'Squash',
            'Strawberry',
            'Tomato',
        ],
    })
    @IsString()
    @IsNotEmpty()
    @IsString()
    @IsNotEmpty()
    selectedCrop: string;

    @ApiProperty({
        description: 'User ID (optional)',
        required: false,
    })
    @IsString()
    @IsOptional()
    userId?: string;
}
