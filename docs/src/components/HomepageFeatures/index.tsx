import clsx from 'clsx';
import Heading from '@theme/Heading';
import styles from './styles.module.css';
import Link from '@docusaurus/Link';
import ThemedImage from '@theme/ThemedImage';
import useBaseUrl from '@docusaurus/useBaseUrl';

type FeatureItem = {
  title: string;
  // Svg: React.ComponentType<React.ComponentProps<'svg'>>;
  description: JSX.Element;
};

function Feature({ title, description }: FeatureItem) {
  return (
    <div className={clsx('col col--4')}>
      <div className="text--center padding-horiz--md">
        <Heading as="h3">{title}</Heading>
        <p>{description}</p>
      </div>
    </div>
  );
}

const list: { name: string, base_path: string }[] = [
  {
    name: 'sokol camera simple',
    base_path: '/wasm/sokol_camera_simple',
  },
  {
    name: 'raylib camera',
    base_path: '/wasm/raylib_camera',
  },
];

export default function HomepageFeatures(): JSX.Element {
  const FeatureList: FeatureItem[] = list.map((x) => {
    return {
      title: x.name,
      description: (<>
        <Link
          target="_blank"
          to={useBaseUrl(x.base_path + ".html")}>
          <ThemedImage
            sources={{
              light: useBaseUrl(x.base_path + ".jpg"),
              dark: useBaseUrl(x.base_path + ".jpg"),
            }} />
        </Link>
      </>
      ),
    }
  });

  return (
    <section className={styles.features}>
      <div className="container">
        <div className="row">
          {FeatureList.map((props, idx) => (
            <Feature key={idx} {...props} />
          ))}
        </div>
      </div>
    </section>
  );
}
