import { Fragment, useContext, useEffect, useState } from 'react';
import { Menu, Transition } from '@headlessui/react';
import { ChevronDownIcon, InformationCircleIcon } from '@heroicons/react/solid';
import CardGridHeader from 'components/CardGridHeader';
import Navbar from 'components/NavBar/NavBar';
import { setSingleActionModal } from 'context/actions';
import { store } from 'context/store';
import { Proposal, ProposalType, Status } from 'interfaces/interfaces';
import * as Icon from 'react-feather';
import ProposalCard from './ProposalCard';
import { ContractsContext } from 'context/Web3/contracts';
import { IpfsClient } from 'utils/IpfsClient';
import { ProposalAdapter } from 'utils/ProposalAdapter';
import {
  ProposalStageExplanations,
  TakedownStageExplanations,
} from './StageExplanations';

export default function ProposalGrid(proposalType: ProposalType): JSX.Element {
  const { dispatch } = useContext(store);
  const [searchFilter, setSearchFilter] = useState<string>('');
  const [statusFilter, setStatusFilter] = useState<Status>(Status.All);
  const { contracts } = useContext(ContractsContext);
  const [proposals, setProposals] = useState<Proposal[]>([]);
  useEffect(() => {
    if (contracts) {
      ProposalAdapter(contracts.beneficiaryGovernance, IpfsClient)
        .getProposals(proposalType)
        .then((res) => setProposals(res));
    }
  }, [contracts]);

  return (
    <div className="w-full bg-gray-900 pb-16">
      <Navbar />
      <CardGridHeader {...proposalType} />
      <div className="grid grid-cols-2 gap-4 items-center justify-start ml-36 mr-64 my-4 h-1/2">
        <div className="relative text-gray-600 focus-within:text-gray-400 ">
          <span className="absolute inset-y-0 left-0 flex items-center pl-2">
            <Icon.Search className="mr-4" />
          </span>
          <div className="mt-1 ">
            <input
              type="search"
              name="searchfilter"
              className="py-2 w-full text-xl text-black bg-white rounded-md pl-10 focus:outline-none focus:bg-white focus:text-gray-900"
              placeholder={
                'Search ' +
                `${
                  proposalType === 0
                    ? 'Eligible Beneficiaries'
                    : 'Takedown Proposals'
                }`
              }
              value={searchFilter}
              onChange={(e) => setSearchFilter(e.target.value)}
            ></input>
          </div>
        </div>
        <span className="mx-4 flex flex-row justify-end items-center">
          <p className="text-lg font-medium text-white">Stage Filter</p>
          <InformationCircleIcon
            onClick={() => {
              dispatch(
                setSingleActionModal({
                  title: 'Beneficiary Nomination Proposal Timeline',
                  content:
                    proposalType === 0 ? (
                      <ProposalStageExplanations />
                    ) : (
                      <TakedownStageExplanations />
                    ),
                  visible: true,
                  onConfirm: {
                    label: 'Close',
                    onClick: () => {
                      dispatch(setSingleActionModal(false));
                    },
                  },
                }),
              );
            }}
            className="h-5 w-5 text-white mx-2"
          />
          <Menu as="div" className="relative inline-block text-left mx-2">
            {({ open }) => (
              <>
                <div>
                  <Menu.Button className="inline-flex justify-center w-full rounded-md border border-gray-300 shadow-sm px-4 py-2 bg-white text-sm font-medium text-gray-700 hover:bg-gray-50 focus:outline-none focus:ring-2 focus:ring-offset-2 focus:ring-offset-gray-100 focus:ring-indigo-500">
                    {Status[statusFilter]}
                    <ChevronDownIcon
                      className="-mr-1 ml-2 h-5 w-5"
                      aria-hidden="true"
                    />
                  </Menu.Button>
                </div>
                <Transition
                  show={open}
                  as={Fragment}
                  enter="transition ease-out duration-100"
                  enterFrom="transform opacity-0 scale-95"
                  enterTo="transform opacity-100 scale-100"
                  leave="transition ease-in duration-75"
                  leaveFrom="transform opacity-100 scale-100"
                  leaveTo="transform opacity-0 scale-95"
                >
                  <Menu.Items
                    static
                    className="origin-top-right absolute right-0 mt-2 w-56 rounded-md shadow-lg bg-white ring-1 ring-black ring-opacity-5 focus:outline-none"
                  >
                    <div>
                      {new Array(6).fill(undefined).map((x, status) => {
                        return (
                          <Menu.Item>
                            {({ active }) => {
                              return (
                                <a
                                  href="#"
                                  onClick={() => setStatusFilter(status)}
                                  className={`block px-4 py-2 text-sm ${
                                    active
                                      ? 'bg-gray-100 text-gray-900'
                                      : 'text-gray-700'
                                  }`}
                                >
                                  {Status[status]}
                                </a>
                              );
                            }}
                          </Menu.Item>
                        );
                      })}
                    </div>
                  </Menu.Items>
                </Transition>
              </>
            )}
          </Menu>
        </span>
      </div>
      <ul className="sm:grid sm:grid-cols-2 gap-x-2 gap-y-12 lg:grid-cols-3 mx-36">
        {proposals
          ?.filter((proposal) => {
            return proposal.application.organizationName
              .toLowerCase()
              .includes(searchFilter.toLowerCase());
          })
          .filter((proposal) => {
            return (
              (proposal as Proposal)?.status === statusFilter ||
              statusFilter === Status.All
            );
          })
          .map((proposal) => (
            <ProposalCard proposal={proposal} proposalType={proposalType} />
          ))}
      </ul>
    </div>
  );
}
