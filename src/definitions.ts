export interface JwPlayerPlugin {
  echo(options: { value: string }): Promise<{ value: string }>;
}
