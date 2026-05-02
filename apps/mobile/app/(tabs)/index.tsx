import { View, Text } from 'react-native';

export default function HomeScreen() {
  return (
    <View className="flex-1 items-center justify-center">
      <Text className="text-2xl font-bold">SakeHub</Text>
      <Text className="mt-2 text-gray-500">Discover & Share Your Favorite Spirits</Text>
    </View>
  );
}
