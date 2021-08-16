// also exported from '@storybook/react' if you can deal with breaking changes in 6.1
import { Meta, Story } from '@storybook/react/types-6-0';
import React from 'react';
import ContractStats from './index';

export default {
  title: 'Popcorn/ContractStats',
  component: ContractStats,
  decorators: [
    (Story) => (
      <div className="flex flex-row justify-center">
        <Story></Story>
      </div>
    ),
  ],
} as Meta;

const Template: Story = (args) => <ContractStats {...args} />;

export const Primary = Template.bind({});
Primary.args = {
  title: 'Example Title',
  content: 'Lorem ipsum lorem ipsum lorem ipsum lorem ipsum',
  place: 'right',
};
