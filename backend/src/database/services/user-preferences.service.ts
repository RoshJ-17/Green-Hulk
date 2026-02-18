import { Injectable, Logger } from "@nestjs/common";
import { InjectRepository } from "@nestjs/typeorm";
import { Repository } from "typeorm";
import { UserPreferences } from "@database/entities/user-preferences.entity";

/**
 * Service for managing user preferences including crop selection memory
 * Task 1.1.4: Crop Memory - Save and retrieve user's last selected crop
 */
@Injectable()
export class UserPreferencesService {
  private readonly logger = new Logger(UserPreferencesService.name);

  constructor(
    @InjectRepository(UserPreferences)
    private readonly preferencesRepository: Repository<UserPreferences>,
  ) {}

  /**
   * Save user's selected crop ID for auto-selection on next app initialization
   * Task 1.1.4: Crop Memory implementation
   */
  async saveLastCrop(userId: number, cropId: string): Promise<UserPreferences> {
    this.logger.debug(
      `Saving last crop selection for user ${userId}: ${cropId}`,
    );

    // Find existing preferences or create new
    let preferences = await this.preferencesRepository.findOne({
      where: { id: userId },
    });

    if (!preferences) {
      preferences = this.preferencesRepository.create({
        id: userId,
        defaultCrop: cropId,
      });
    } else {
      preferences.defaultCrop = cropId;
    }

    const saved = await this.preferencesRepository.save(preferences);
    this.logger.log(`Crop selection saved: ${cropId} for user ${userId}`);

    return saved;
  }

  /**
   * Retrieve user's last selected crop for UI auto-selection
   * Task 1.1.4: Query database on app initialization
   */
  async getLastCrop(userId: number): Promise<string | null> {
    this.logger.debug(`Retrieving last crop for user ${userId}`);

    const preferences = await this.preferencesRepository.findOne({
      where: { id: userId },
    });

    if (!preferences || !preferences.defaultCrop) {
      this.logger.debug(`No saved crop found for user ${userId}`);
      return null;
    }

    this.logger.debug(`Found saved crop: ${preferences.defaultCrop}`);
    return preferences.defaultCrop;
  }

  /**
   * Get all user preferences
   */
  async getUserPreferences(userId: number): Promise<UserPreferences | null> {
    return this.preferencesRepository.findOne({
      where: { id: userId },
    });
  }

  /**
   * Create or update user preferences
   */
  async updatePreferences(
    userId: number,
    updates: Partial<UserPreferences>,
  ): Promise<UserPreferences> {
    let preferences = await this.preferencesRepository.findOne({
      where: { id: userId },
    });

    if (!preferences) {
      preferences = this.preferencesRepository.create({
        id: userId,
        ...updates,
      });
    } else {
      Object.assign(preferences, updates);
    }

    return this.preferencesRepository.save(preferences);
  }

  /**
   * Save preferred language setting
   * Task 1.2.3: Language selection persistence
   */
  async saveLanguage(
    userId: number,
    language: string,
  ): Promise<UserPreferences> {
    this.logger.debug(
      `Saving language preference for user ${userId}: ${language}`,
    );
    return this.updatePreferences(userId, { preferredLanguage: language });
  }

  /**
   * Get user's preferred language
   */
  async getPreferredLanguage(userId: number): Promise<string | null> {
    const preferences = await this.getUserPreferences(userId);
    return preferences?.preferredLanguage || null;
  }

  /**
   * Toggle organic treatment preference
   * Task 3.2.1: Organic filter preference
   */
  async setOrganicPreference(
    userId: number,
    preferOrganic: boolean,
  ): Promise<UserPreferences> {
    this.logger.debug(
      `Setting organic preference for user ${userId}: ${preferOrganic}`,
    );
    return this.updatePreferences(userId, {
      preferOrganicTreatments: preferOrganic,
    });
  }

  /**
   * Get organic treatment preference
   */
  async getOrganicPreference(userId: number): Promise<boolean> {
    const preferences = await this.getUserPreferences(userId);
    return preferences?.preferOrganicTreatments ?? true; // Default to true
  }
}
