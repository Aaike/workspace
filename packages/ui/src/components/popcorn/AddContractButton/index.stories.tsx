// also exported from '@storybook/react' if you can deal with breaking changes in 6.1
import { Meta, Story } from '@storybook/react/types-6-0';
import React from 'react';
import AddContractButton from './index';

export default {
  title: 'Popcorn/AddContractButton',
  component: AddContractButton,
  decorators: [
    (Story) => (
      <div className="flex flex-row justify-center">
        <Story></Story>
      </div>
    ),
  ],
} as Meta;

const Template: Story = (args) => <AddContractButton {...args} />;

export const Primary = Template.bind({});
Primary.args = {
  title: 'Example Title',
  content: 'Lorem ipsum lorem ipsum lorem ipsum lorem ipsum',
  place: 'right',
};
