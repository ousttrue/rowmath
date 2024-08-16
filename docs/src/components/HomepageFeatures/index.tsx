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

export default function HomepageFeatures(): JSX.Element {
  const FeatureList: FeatureItem[] = [
    {
      title: 'sokol camera',
      // Svg: require('@site/static/img/undraw_docusaurus_mountain.svg').default,
      description: (
        <>
          <Link
            target="_blank"
            to={useBaseUrl("/wasm/sokol_camera.html")}>
            <ThemedImage
              sources={{
                light: useBaseUrl("/wasm/sokol_camera.jpg"),
                dark: useBaseUrl("/wasm/sokol_camera.jpg"),
              }} />
          </Link>
        </>
      ),
    },
    {
      title: 'raylib camera',
      // Svg: require('@site/static/img/undraw_docusaurus_tree.svg').default,
      description: (
        <>
          <Link
            target="_blank"
            to={useBaseUrl("/wasm/raylib_camera.html")}>
            <ThemedImage
              sources={{
                light: useBaseUrl("/wasm/raylib_camera.jpg"),
                dark: useBaseUrl("/wasm/raylib_camera.jpg"),
              }} />
          </Link>
        </>
      ),
    },
  ];

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
