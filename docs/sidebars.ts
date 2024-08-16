import type { SidebarsConfig } from '@docusaurus/plugin-content-docs';

const sidebars: SidebarsConfig = {
  tutorialSidebar: [
    'intro',
    {
      type: 'category',
      label: 'examples',
      items: [
        {
          type: 'category',
          label: 'sokol',
          items: [
            'examples/sokol/camera',
          ]
        },
        {
          type: 'category',
          label: 'raylib',
          items: [
            'examples/raylib/camera',
          ]
        },
      ],
    },
  ],
};

export default sidebars;
