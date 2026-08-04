# Platform-service Helm value contracts

These files are production configuration contracts, not Helm charts and not
directly executable release values. They intentionally define no dependencies,
templates, namespaces, CRDs, or release commands. Before any future use, pin an
approved upstream chart version, compare its published schema with the matching
contract, render offline, review the result, and use approved change control.

All `enabled` fields in these contracts are safeguards for the future automation
layer. They do not install or disable an upstream chart by themselves.
