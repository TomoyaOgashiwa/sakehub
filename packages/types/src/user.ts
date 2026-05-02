export type User = {
  id: string;
  email: string;
  displayName: string;
  avatarUrl?: string;
  createdAt: string;
  updatedAt: string;
};

export type UserProfile = User & {
  bio?: string;
  favoriteCategory?: string;
  totalDrinks: number;
  totalReviews: number;
};

export type DrinkLog = {
  id: string;
  userId: string;
  drinkId: string;
  drankAt: string;
  createdAt: string;
};
