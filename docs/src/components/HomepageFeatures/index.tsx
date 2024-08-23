import clsx from 'clsx';
import Heading from '@theme/Heading';
import styles from './styles.module.css';
import Link from '@docusaurus/Link';
import ThemedImage from '@theme/ThemedImage';
import useBaseUrl from '@docusaurus/useBaseUrl';
import list from './list.json';

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
  const FeatureList: FeatureItem[] = list.map((x) => {
    return {
      title: x.name,
      description: (<>
        <Link
          target="_blank"
          to={useBaseUrl(`/wasm/${x.base_name}.html`)}>
          <ThemedImage
            sources={{
              light: useBaseUrl(`/wasm/${x.base_name}.jpg`),
              dark: useBaseUrl(`/wasm/${x.base_name}.jpg`),
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
