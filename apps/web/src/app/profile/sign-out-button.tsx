import { cn } from '@/utils/utils';

import { signOut } from '../(auth)/actions';
import { profileHubRowClassName } from './profile-hub-styles';

export function SignOutButton() {
  return (
    <form action={signOut}>
      <button
        type="submit"
        className={cn(profileHubRowClassName, 'cursor-pointer border-0 bg-transparent')}
      >
        ログアウト
      </button>
    </form>
  );
}
