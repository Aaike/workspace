import { EmissionStats } from 'interfaces';
import React from 'react';
import {
  Area,
  Bar,
  CartesianGrid,
  ComposedChart,
  ResponsiveContainer,
  Tooltip,
  XAxis,
  YAxis,
} from 'recharts';

export interface AreaChartProps {
  data: EmissionStats[];
  height?: number;
  width?: number;
}

export const AreaBarChart: React.FC<AreaChartProps> = ({
  data,
  height,
  width,
}) => {
  return (
    <div className="w-screen grid justify-items-stretch">
      <ResponsiveContainer
        className="justify-self-start ml-3"
        width="87%"
        height={height}
      >
        <ComposedChart data={data}>
          <XAxis dataKey="blockStartDate" scale="band" hide={true}></XAxis>
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
            stroke="#C7D2FE"
            yAxisId="left"
          />
          <Bar
            yAxisId="right"
            dataKey="numTransactions"
            barSize={20}
            fill="#4F46E5"
          />
        </ComposedChart>
      </ResponsiveContainer>
    </div>
  );
};
