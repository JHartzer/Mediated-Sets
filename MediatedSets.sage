# Class: MaxMediatedSet
#
# Author: Jacob Hartzer, Timo de wolff
# Last Edited 10/01/2016
#
# Class written for the analysis of maximal mediated sets
#
###############################################################################
#
#	Usage:
# 
#	load("/path/to/file/MediatedSets.sage")
#	M = MaxMediatedSet((List of tuples to define an all even polytope))
#	M.plot()
#
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
		'''Class initializer'''
		if self._input_check(input_points):
			self._define(input_points)
			
			
	def _input_check(self,input_points):
		'''Checks that the input are of the same dimension'''
		for i in range(1,len(input_points)):
			if len(input_points[0]) != len(input_points[i]):
				print 'Error: Input points must be of same dimension'
				return false
		return true	
		
		
	def _define(self,input_points):
		'''Converts input points to vertices and lattice'''
		self.game_played = false
		P = LatticePolytope_PPL(input_points)
		self.lattice = np.array(P.integral_points()).tolist()	
		self.remaining_points = np.array(P.integral_points()).tolist()
		self.vertices = np.array(P.vertices()).tolist()
		
	
	def compute_maxmediatedset(self):
		'''Process to find the maximal mediated set'''
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
		'''Plots the polytope and the maximal mediated set'''
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
			
			
	def percent_h(self):
		'''Calculates %H'''
		if not self.game_played:
			self.compute_maxmediatedset()
		print (self.minimal_set_size(),len(self.remaining_points),\
		len(self.lattice)), \
		float("{0:.2f}".format(float(len(self.remaining_points)\
		-self.minimal_set_size())/float(len(self.lattice)\
		-self.minimal_set_size())*100)), '%'

				
	def minimal_set_size(self):
		'''Calculates the minimum size of the maximal mediated set. 
		Essentially, the number of vertices and midpoints.'''
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
	
	
	

	

