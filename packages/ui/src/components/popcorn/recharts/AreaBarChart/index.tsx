import React from 'react';
import {
  Area,
  Bar,
  CartesianGrid,
  ComposedChart,
  Tooltip,
  XAxis,
  YAxis,
} from 'recharts';
import { ChartData } from '../AreaChart';

export interface AreaChartProps {
  data: ChartData[];
  height?: number;
  width?: number;
}

export const AreaBarChart: React.FC<AreaChartProps> = ({
  data,
  height,
  width,
}) => {
  return (
    <ComposedChart width={width} height={height} data={data}>
      <XAxis dataKey="date" scale="band" hide={true}></XAxis>
      <YAxis
        yAxisId="left"
        orientation="left"
        dataKey="numTransactions"
        tick={false}
        hide={true}
      />
      <YAxis
        yAxisId="right"
        orientation="right"
        dataKey="co2Emissions"
        tick={false}
        hide={true}
      />
      <Tooltip />
      <CartesianGrid stroke="#f5f5f5" />
      <Area
        type="monotone"
        dataKey="co2Emissions"
        stroke="#34D399"
        yAxisId="left"
      />
      <Bar
        yAxisId="right"
        dataKey="numTransactions"
        barSize={20}
        fill="#818CF8"
      />
    </ComposedChart>
  );
};
