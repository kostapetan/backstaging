import {
    TechRadarLoaderResponse,
    TechRadarApi,
  } from '@backstage/plugin-tech-radar';
  
  import { ConfigApi } from '@backstage/core-plugin-api';
  
  export class TechRadarClient implements TechRadarApi {
    config: ConfigApi;
    constructor(config: ConfigApi) {
      this.config = config;
    }
    async load(_id: string | undefined): Promise<TechRadarLoaderResponse> {
      
      const backendUrl = this.config.getString('backend.baseUrl');
      const payload = await fetch(`${backendUrl}/api/proxy/discussions/`)
         .then(response => response.json());
      
         return {
          ...payload,
          entries: payload.entries.map((entry: { timeline: any[]; }) => ({
            ...entry,
            timeline: entry.timeline.map(timeline => ({
              ...timeline,
              date: new Date(timeline.date),
            })),
          })),
        };
    }
  }