# Mediated-Sets
This is a work in progress by Jacob Hartzer and Timo de Wolff from the Texas A&M Department of Mathematics

Usage

To set up your machine to use **"Maximal_Mediated_Sets.sage"**, proceed as follows:

1. Install **SAGE** to your machine. Instructions for doing so can be found here.
2. You download our software package; save it into **"~/YOUR_FOLDER/"**.
3. Start **SAGE** and execute the command:
> load('~/YOUR_FOLDER/MediatedSets.sage')
4. You can now use the software.
* We define an instance of our class **MaxMediatedSet** :
> M = MaxMediatedSet(((0,0),(4,2),(2,4)))
* The input is a list of integer tuples with all even entries. The maximal mediated set is a particular subset of all lattice points inside the polytope which is defined by the input. In what follows we refer to this set of all lattice points as L1. It can be viewed by
> M.lattice
* We compute the corresponding maximal mediated set using Reznick's algorithm:
> M.compute_maxmediatedset()
* Every maximal mediated set contains at least the vertices of the defining polytope and the midpoints of two vertices, i.e. one further point for every edge. In what follows we refer to this set as L2. The following command computes a tuple providing the cardinalities L2, the maximal mediated set, and the set L1. Moreover, it provides the percentage of elements from L1 - L2, which is contained in the maximal mediated set.
> M.percent_h()
* If the maximal mediated set, which we have computed, lies in dimension 2 or 3, then we can plot a graphical output:
> M.plot()
License

The Software is published under GNU public license.

Literature

1. S. Iliman, T. de Wolff: "Amoebas, Nonnegative Polynomials and Sums of Squares Supported on Circuits", Research in the Mathematical Sciences 3 (1), 2016, 1-35; see Open Access Version.
2. B. Reznick: "Forms derived from the arithmetic-geometric inequality", Mathematische Annalen 283 (3), 1989, 431-464.
