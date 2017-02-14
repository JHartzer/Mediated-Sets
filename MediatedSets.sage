# Class: MaxMediatedSet
#
# Author: Jacob Hartzer, Timo de wolff
# Last Edited: 14 - February - 2016
#
# Class written for the analysis of maximal mediated sets
#
###############################################################################

# Class for quick building of lattice points
from sage.geometry.polyhedron.ppl_lattice_polytope import LatticePolytope_PPL

# Used to convert the polytope lattice type to a list type
import numpy as np

# For permutations
import itertools as itr

# Database package
import sqlite3

class MaxMediatedSet:
    '''Class for analyzing maximal mediated sets and their properties'''


    def __init__(self, input_points):
        """Construct a Mediated Set object."""
        if self._input_check(input_points):
            self._define(input_points)
            
            
    def _input_check(self,input_points):
        '''Checks the input'''
        for i in range(1,len(input_points)):
            if len(input_points[0]) != len(input_points[i]):
                print 'Error: Input points must be of same dimension'
                return false
        if len(input_points) <= len(input_points[0]):
            print 'Error: Underdefined simplex'
            return false
        return true    
        
        
    def _define(self,input_points):
        '''Converts input points to vertices and calculates lattice'''
        self.game_played = false
        P = LatticePolytope_PPL(input_points)
        self.lattice = np.array(P.integral_points()).tolist()    
        self.remaining_points = np.array(P.integral_points()).tolist()
        self.vertices = np.array(P.vertices()).tolist()
        
    
    def compute_maxmediatedset(self):
        r"""
        Computes the maximal mediated set of the input points. 

        INPUT:

        - ``input_points`` -- tuple of tuple of equal length. This is a tuple of 
            the tuples of length (dimension + 1) that define a simplex within
          the given dimension. 
        
        - ``self.lattice`` -- tuple of tuples. A tuple of all the points within
          or on the face of the defined simplex.
        
        - ``self.remaining_points`` -- tuple of tuples. List that is used 
          recursively to keep track of which points are still within the 
          maximal mediated set after each iteration.
        
        - ``self.vertices`` -- tuple of tuples. List of all the vertices of the
          simplex. Equal to ''input_points''.

        OUTPUT:

        The maximal mediated set as a list of lists.

        .. SEEALSO::

            :func:`plot`
            :func:`minimal_set_size`

        ALGORITHM:
        
            Timo, I'll need you to put in a reference here so I can better 
            document it.
            
        EXAMPLES:

        This example illustrates the creation and calculation of a Maximal 
        Mediated Set in the second demension. 

        ::

            sage: M = MaxMediatedSet(((0,0),(2,4),(4,2)))
            sage: M.compute_maxmediatedset()
            [[0, 0], [1, 2], [2, 1], [2, 4], [3, 3], [4, 2]]
            
            
        This example illustrates the creation and calculation of a Maximal 
        Mediated Set in the third demension. 
        
        ::
        
            M = MaxMediatedSet(((0,0,0),(0,2,4),(0,4,2),(2,2,4)))
            M.compute_maxmediatedset()        
            [[0, 0, 0],
             [0, 1, 2],
             [0, 2, 1],
             [0, 2, 4],
             [0, 3, 3],
             [0, 4, 2],
             [1, 1, 2],
             [1, 2, 4],
             [1, 3, 3],
             [2, 2, 4]]

        ...

        TESTS::

            sage: M = MaxMediatedSet(((0,0),(2,4)))  # Checks for case of\ 
            underdefined simplex
                Error: Underdefined simplex
            
            sage: M = MaxMediatedSet(((0,0),(0,0),(0,2,4)))  # Checks for case\ 
            of mismatched point dimensions
                Error: Input points must be of same dimension
            
        .. automethod:: _keep
        """
        
        for i in range(len(self.remaining_points)-1,0,-1):
            if self.remaining_points[i] not in tuple(self.vertices) \
            and not self._keep(i,self.remaining_points):
                self.remaining_points.remove(self.remaining_points[i])
                self.compute_maxmediatedset()
                break
        self.game_played = true
        return self.remaining_points
                    
                    
    def _keep(self, test_point_index, remaining_points):
        '''Boolean test for condition to keep in maximal mediated set'''
        for i in range(0,test_point_index):
            if self._all_even(i,remaining_points):
                coordinate = []
                for j in range(len(remaining_points[0])):
                    coordinate.append(2*remaining_points[test_point_index][j] \
                    - remaining_points[i][j])
                for k in range(len(remaining_points)-1,test_point_index,-1):
                    if coordinate == remaining_points[k]:
                        return true
        return false
    
    
    def _all_even(self, point_index, remaining_points):
        '''Determines if the coordinates of a point are all even'''
        for i in range(len(remaining_points[point_index])):
            if remaining_points[point_index][i]%2 != 0:
                return false
        return true

        
    def plot(self):
        r"""
        Plots the maximal mediated set

        INPUT:

        - ``self`` -- 2nd or 3rd dimensional MaxMediatedSet Object. This is the
          object containing the lists of vertices, remaining_points, and 
          lattice. If the set has not already been calculated, it will be 
          before plotting.

        OUTPUT:

        2 or 3 dimensional plot of the maximal mediated set, depending on the 
        dimension of the input points. 

        EXAMPLES:

        This example illustrates plotting 2 or 3 dimensional Max Mediated Sets.

        ::

            sage: M = MaxMediatedSet(((0,0,0),(0,2,4),(0,4,2),(4,2,2)))
            sage: M.plot()
            <3d plot of simplex>

        ::

            sage: M = MaxMediatedSet(((0,0),(2,4),(4,2)))
            sage: M.plot()
            <2d plot of simplex>
                
        It is an error to plot a MMSet with dimension other than 2 or 3

            sage: M = MaxMediatedSet(((0,0,0,0),(2,4,0,0),(4,2,0,0),(0,2,4,0),\
            (0,0,4,2)))
            sage: M.plot()
            Error: Polytope must have dimension of 2 or 3 to graph


        .. NOTE::

            Orange points are the original lattice, and red points are all 
            those remaining in the set.


        """
        if not self.game_played:
            self.compute_maxmediatedset()
        if len(self.vertices[0]) == 2:
            show(sage.plot.polygon.polygon(self.vertices,fill = false)\
            +point(self.lattice, color = 'orange', size = 40)\
            +point(self.remaining_points, color = 'red', size = 40)\
            +point(self.vertices, color = 'red', size = 40))
        elif len(self.vertices[0]) == 3:
            show(Polyhedron(self.vertices).plot(fill=false)
            +point(self.lattice, color = 'orange', size = 20)\
            +point(self.remaining_points, color = 'red', size = 20)\
            +point(self.vertices, color = 'red', size = 20))
        else:
            print 'Error: Polytope must have dimension of 2 or 3 to graph'
            
                
    def minimal_set_size(self):
        r"""
        Return the smallest possible size of the maximal mediated set.

        INPUT:

        - ``self.vertices`` -- tuple of tuples. These are the points that 
        define the simplex

        OUTPUT:

        The integer minimum set size.

        .. SEEALSO::

            :func:`compute_maxmediatedset`

        EXAMPLES:

        This example illustrates caclulating the minimum set size

        ::

            sage: M = MaxMediatedSet(((0,0,0),(2,4,0),(4,2,0),(0,2,4)))
            sage: M.minimal_set_size()
            10
        
        ::
        
            sage: M = MaxMediatedSet(((0,0),(2,4),(4,2)))
            sage: M.minimal_set_size()
            6 
        """
        return len(self.vertices)\
        +((len(self.vertices) - 1)*len(self.vertices)) / 2
            
    
def power_set(n,size):
    '''Creates the power set of all possible simplicies in dimension 
    n up to a given size in any direction along with the number of repeats for 
    each unique set of points.'''
    all_matricies = []
    my_dict = {}
    
    all_points = list(itr.product(range(0,size+1,2),repeat = n))
    all_points.remove(tuple([0]*n))
    all_sets = (list(itr.combinations(all_points,n)))

    for i in range(0,len(all_sets)):
        all_matricies.append(np.array(all_sets[i]))
        my_dict[all_sets[i]] = [false, 0]

    for i in range(len(all_matricies)):
        if not my_dict[tuple(map(tuple, all_matricies[i]))][0]:
            column_vectors = []
            for j in range(len(all_matricies[i][0])):
                column_vectors.append(all_matricies[i][:,j])
            for column_permutation in list(itr.permutations(column_vectors)):
                key = tuple(map(tuple,sorted(tuple(map(tuple,np.column_stack(\
                column_permutation))))))
                
                my_dict[key][0] = true
                my_dict[key][1] = my_dict[key][1] + 1
    return my_dict
                
                
def create_db(Name):
    '''Creates a database table with a given name for the MMSet type'''
    conn = sqlite3.connect(Name)
    c = conn.cursor()
    c.execute('''CREATE TABLE MMSet (Vertices TEXT, MMSet TEXT, 'Max Set Size' 
    INTEGER, 'MMSet size' INTEGER, 'Min Set Size' INTEGER, Difference INTEGER, 
    Degree INTEGER, Orbits INTEGER)''')
    conn.commit()
    conn.close()

    
def add_mmset(Name,Vertices,MMSet,Max,SetSize,Min,Degree,Orbits):
    '''Adds element to the MMSet database table'''
    conn = sqlite3.connect(Name)
    c = conn.cursor()
    addSet = (str(Vertices),str(MMSet),int(Max),int(SetSize),int(Min),\
        int(Max-SetSize),int(Degree),int(Orbits))
    c.execute("INSERT INTO MMSet VALUES (?,?,?,?,?,?,?,?)", addSet)
    conn.commit()

        
def create_dimension_table(dimension,size):
    '''Creates a database table for a given dimension up to a certain size. 
    Generates power set and removes all rotations and counts orbits. Lists 
    each unique Mediated Set and its maximal set, maximal set size, minimal set
    size, and orbits.'''
    name = "DB_dimension_%s.db" % (dimension)
    my_dict = power_set(dimension,size)
    create_db(name)
    for key in my_dict:
        M = MaxMediatedSet(((0,)*dimension,) + key)
        MMSet = M.compute_maxmediatedset()
        add_mmset(name,str(((0,)*dimension,) + key),str(MMSet),len(M.lattice),\
        len(MMSet),M.minimal_set_size(),max(map(sum, key)),my_dict[key][1])
    
    
    

    

