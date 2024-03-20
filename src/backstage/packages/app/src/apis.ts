import {
  ScmIntegrationsApi,
  scmIntegrationsApiRef,
  ScmAuth,
} from '@backstage/integration-react';
import {
  AnyApiFactory,
  configApiRef,
  createApiFactory,
} from '@backstage/core-plugin-api';

import { TechRadarClient } from './lib/RadarDataClient';
import { techRadarApiRef } from '@backstage/plugin-tech-radar';

export const apis: AnyApiFactory[] = [
  createApiFactory({
    api: scmIntegrationsApiRef,
    deps: { configApi: configApiRef },
    factory: ({ configApi }) => ScmIntegrationsApi.fromConfig(configApi),
  }),
  ScmAuth.createDefaultApiFactory(),
  createApiFactory(
    {
      api: techRadarApiRef,
      deps: { configApi: configApiRef },
      factory: ({ configApi }) => new TechRadarClient(configApi),
    },),
];
