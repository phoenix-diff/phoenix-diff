import { test, expect } from '@playwright/test';

test('basic version switching', async ({ page }) => {
  await page.goto('/compare/1.6.0...1.6.1');

  // Expect a title "to contain" a substring.
  await expect(page).toHaveTitle(/v1\.6\.0/);

  await expect(page.getByText('Files changed (2)')).toBeVisible();

  await page.getByRole('group', { name: 'Target' }).getByLabel('Version').selectOption('1.6.0');

  await page.getByRole('button', { name: 'Generate Diff' }).click({ force: true });

  await expect(page.getByText('There are no changes between')).toBeVisible();
});
