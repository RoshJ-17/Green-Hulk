import { Repository } from 'typeorm';
import { UserPreferences } from '@database/entities/user-preferences.entity';
export declare class UserPreferencesService {
    private readonly preferencesRepository;
    private readonly logger;
    constructor(preferencesRepository: Repository<UserPreferences>);
    saveLastCrop(userId: number, cropId: string): Promise<UserPreferences>;
    getLastCrop(userId: number): Promise<string | null>;
    getUserPreferences(userId: number): Promise<UserPreferences | null>;
    updatePreferences(userId: number, updates: Partial<UserPreferences>): Promise<UserPreferences>;
    saveLanguage(userId: number, language: string): Promise<UserPreferences>;
    getPreferredLanguage(userId: number): Promise<string | null>;
    setOrganicPreference(userId: number, preferOrganic: boolean): Promise<UserPreferences>;
    getOrganicPreference(userId: number): Promise<boolean>;
}
