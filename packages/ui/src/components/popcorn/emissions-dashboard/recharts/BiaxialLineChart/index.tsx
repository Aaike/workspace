import React from 'react';
import {
  CartesianGrid,
  Line,
  LineChart,
  ResponsiveContainer,
  Tooltip,
  XAxis,
  YAxis,
} from 'recharts';
import { TransactionGroupSummary } from '../../../../../interfaces/emissions-dashboard';
import Spinner from '../../Spinner';

export interface BiaxialLineChartProps {
  data: TransactionGroupSummary[];
  height?: number;
  width?: number;
  areaColor?: string;
  barColor?: string;
  gridColor?: string;
}

const CustomTooltip = ({ active, payload, label }) => {
  if (active && payload && payload.length) {
    return (
      <div className="bg-gray-50 p-1">
        <p className="text-xs ">{`${label}`}</p>
        <p className="text-xs text-indigo-500">{`Transaction Volume: ${payload[0].value}`}</p>
        <p className="text-xs text-green-500">{`CO2 Emissions (µg): ${payload[1].value}`}</p>
      </div>
    );
  }

  return null;
};

export const ChartLoading: React.FC<{ height: number }> = ({ height }) => {
  return (
    <div
      className="w-full flex flex-wrap content-center border-2 border-gray-50 "
      style={{
        objectFit: 'cover',
        height: height,
        marginTop: 5,
        marginRight: 30,
        marginLeft: 30,
        marginBottom: 5,
      }}
    >
      <Spinner />
    </div>
  );
};

export const ChartError: React.FC<{ height: number }> = ({ height }) => {
  return (
    <div
      className="w-full flex flex-wrap content-center border-2 border-gray-50 justify-center "
      style={{
        objectFit: 'cover',
        height: height,
        marginTop: 5,
        marginRight: 30,
        marginLeft: 30,
        marginBottom: 5,
      }}
    >
      <p className="text-lg text-gray-500">Error loading transactions</p>
    </div>
  );
};

export const BiaxialLineChart: React.FC<BiaxialLineChartProps> = ({
  data,
  height,
  areaColor = '#C7D2FE',
  barColor = '#4F46E5',
  gridColor = '#E0E0E0',
}) => {
  const containsData =
    data.reduce((pr, cu) => {
      return pr + cu.co2Emissions;
    }, 0) > 0;
  return containsData ? (
    <ResponsiveContainer
      className="justify-self-center"
      width="100%"
      height={height}
    >
      <LineChart
        data={data}
        margin={{
          top: 5,
          right: 30,
          left: 30,
          bottom: 5,
        }}
      >
        <CartesianGrid stroke="#f5f5f5" />
        <XAxis dataKey="blockStartDate" hide={true} />
        <YAxis dataKey="numTransactions" yAxisId="left" hide={true} />
        <YAxis
          dataKey="co2Emissions"
          yAxisId="right"
          orientation="right"
          hide={true}
        />

        <Line
          yAxisId="left"
          type="monotone"
          dataKey="numTransactions"
          stroke="#7c3aed" // indigo-500
          activeDot={{ r: 8 }}
        />
        <Line
          yAxisId="right"
          type="monotone"
          dataKey="co2Emissions"
          fill="#10b981" // green-500
        />
        <Tooltip
          content={
            <CustomTooltip
              active={undefined}
              payload={undefined}
              label={undefined}
            />
          }
        />
      </LineChart>
    </ResponsiveContainer>
  ) : (
    <div
      className="w-full flex flex-wrap content-center border-2 border-gray-50 justify-center "
      style={{
        objectFit: 'cover',
        height: height,
        marginTop: 5,
        marginRight: 30,
        marginLeft: 30,
        marginBottom: 5,
      }}
    >
      <p className="text-lg text-gray-500">No transactions were made</p>
    </div>
  );
};