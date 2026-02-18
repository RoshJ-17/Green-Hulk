import { IsString, IsNotEmpty } from "class-validator";
import { ApiProperty } from "@nestjs/swagger";

export class DiagnoseRequestDto {
  @ApiProperty({
    description: "Selected crop type",
    example: "Tomato",
    enum: [
      "Apple",
      "Blueberry",
      "Cherry",
      "Corn",
      "Grape",
      "Orange",
      "Peach",
      "Pepper",
      "Potato",
      "Raspberry",
      "Soybean",
      "Squash",
      "Strawberry",
      "Tomato",
    ],
  })
  @IsString()
  @IsNotEmpty()
  selectedCrop: string;
}
