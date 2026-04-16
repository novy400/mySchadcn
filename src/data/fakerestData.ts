import baseData from './raw/baseData';
import { buildSummaries } from './projections/buildSummaries';

const fakerestData = buildSummaries(baseData);

export default fakerestData;
