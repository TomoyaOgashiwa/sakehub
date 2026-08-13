export type User = {
  id: string;
  email: string;
  displayName: string;
  avatarUrl?: string;
  loginType: string;
  createdAt: string;
  updatedAt: string;
};

export type UserProfile = User & {
  bio?: string;
  favoriteCategory?: string;
  totalDrinks: number;
  totalReviews: number;
};
