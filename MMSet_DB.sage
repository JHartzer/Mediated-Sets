# Class: MMSet_DB
#
# Author: Jacob Hartzer, Timo de wolff
# Last Edited: 9 - September - 2017
#
# Class written for the analysis of maximal mediated set databases 
#
###############################################################################
import os

base_path = "/media/sf_GIT/Mediated-Sets/DB/"

class MMSet_DB:
    '''Class for creating maximal mediated sets databases'''


    def __init__(self):
        """Construct a Mediated Set database object."""
        
        
    def load_data_table(self,filename):
        if not os.path.isfile(os.path.join(base_path, filename)):
            return 'Error: File does not exist'
        else:
            self.path = os.path.join(base_path, filename)
            self.open_db()
            self.conn.commit()
            self.close_db()
            self.database_computed = true

    
    def create_new_table(self, dim, degree):
        self.dim = dim
        self.degree = degree
        filename = "DB_dimension_%s_degree_%s.db" % (dim,degree)
        self.path = os.path.join(base_path, filename)
        if not os.path.isfile(os.path.join(base_path, filename)): 
            self.open_db()
            c = self.conn.cursor()
            c.execute('''CREATE TABLE MMSet (Vertices TEXT, MMSet TEXT, 'Max Set Size' INTEGER, 'MMSet size' INTEGER, 'Min Set Size' INTEGER, Percent TEXT, Degree INTEGER, Orbits INTEGER)''')
            self.conn.commit()
            self.database_computed = false
        else:
            print 'Table already exists'
            self.load_data_table(filename)
            print 'Existing table loaded'
        self.close_db()
        


    def open_db(self):
        self.conn = sqlite3.connect(self.path)

        
    def close_db(self):
        self.conn.close()
        

    def add_mmset(self,Vertices,MMSet,Max,SetSize,Min,Degree,Orbits):
        '''Adds element to the MMSet database table'''
        c = self.conn.cursor()
        if Max == Min:
            percent = str('N/A')
        else:
            percent = str(float((SetSize-Min)/(Max-Min)*100))
        addSet = (str(Vertices),str(MMSet),int(Max),int(SetSize),int(Min),\
            percent,int(Degree),int(Orbits))
        c.execute("INSERT INTO MMSet VALUES (?,?,?,?,?,?,?,?)", addSet)
        self.conn.commit()  
        
        
    def compute_dimension_table(self):    
        '''Creates a database table for a given dimension up to a certain degree. 
        Generates power set and removes all rotations and counts orbits. Lists 
        each unique Mediated Set and its maximal set, maximal set size, minimal set
        size, and orbits.'''
        if self.database_computed == false:
            files = os.listdir(base_path)
            for file in files:
                dim_index = file.find('dimension_')
                deg_index = file.find('degree_')
                if self.dim == int(file[dim_index+10:deg_index-1]) and self.degree < int(file[deg_index+7:len(file)-3]):
                    print 'Warning: Table of equal or higher degree already exists.'
                    return
            
            t_start = time.time()
            self.open_db()
            
            standard_points = []
            for i in range(1,self.dim+1):
                point = [0,]*self.dim
                point[i-1] = self.degree/2
                standard_points.append(point)
            standard_points.append([0,]*self.dim)
            all_points = np.array(LatticePolytope_PPL(standard_points).integral_points()).tolist()
            for i in range(len(all_points)):
                for j in range(len(all_points[0])):
                    all_points[i][j] = (all_points[i][j] * 2)

            all_points.remove([0]*self.dim)    

            self._power_set(all_points)
            c = self.conn.cursor()
            c.execute('SELECT Sum(Orbits) FROM MMSet')
            num_sets = c.fetchone()
            total_time = time.time()-t_start
            print num_sets[0], 'MMSets analyzed in', total_time, 'seconds'
            self.close_db()
            self.database_computed = true
        
    def _power_set(self,all_points):
        '''Creates the power set of all possible simplicies in dimension 
        n up to a given degree in any direction along with the number of repeats for 
        each unique set of points.'''
        ticker = range(0,self.dim)
        n = 1
        c = self.conn.cursor()
        t0 = time.time()
        while true:
            if n % 100 == 0:
                if time.time()-t0 > 30:
                    print '%i Point Sets Checked' %n
                    t0 = t0+30
            n = n + 1
            base_simplex = self._find_base_simplex(ticker,all_points)
            points = self._index_to_points(list(set(base_simplex)),all_points) 
            
            if matrix_rank(points) == self.dim:
                points.sort()
                entry = str([[0,]*self.dim,] + points)
                
                c.execute('SELECT Orbits FROM MMSet WHERE Vertices =?', (entry,))
                new_orbit = c.fetchone()
            
                if new_orbit is None:
                    M = MaxMediatedSet([[0,]*self.dim,] + points)
                    MMSet = M.compute_maxmediatedset()
                    self.add_mmset(str([[0,]*self.dim,] + points),str(MMSet),len(M.lattice),len(MMSet),M.minimal_set_size(),max(map(sum, points)),1) 
                    
                else:            
                    new_orbit = int(new_orbit[0] + 1)
                    c.execute('UPDATE MMSet SET Orbits = ? WHERE Vertices=?',(new_orbit,entry))
                    self.conn.commit()
            if ticker[self.dim-1] == len(all_points) -1:
                
                for i in range(self.dim-2,-1,-1):
                    if ticker[i] + 1 != ticker[i+1]:
                        break        
            
                if i == 0 and ticker[0] +1 == ticker[1]:
                    break
     
                ticker[i] = ticker[i] + 1 
                ticker[i+1:self.dim] = range(ticker[i]+1,ticker[i] + self.dim - i)
                ticker[self.dim-1] = ticker[self.dim-1] -1

            ticker[self.dim-1] = ticker[self.dim-1] +1

        
    def _find_base_simplex(self, ticker,all_points):
        '''Checks if the given simlex is the base simplex out of all possible permutations about lines of symmetry'''
        points = [0,]*len(ticker)
        for i in range(len(ticker)):
            points[i] = all_points[ticker[i]]
        point_matrix = np.array(points)
      
        column_vectors = []
        for j in range(len(points)):
            column_vectors.append(point_matrix[:,j])
        
        indices = []
        column_permutations = list(itr.permutations(column_vectors))
        
        for column_permutation in column_permutations:

            key = np.column_stack(column_permutation)
            purmutation_index = [0,]*len(key)
            for i in range(len(key)):
                purmutation_index[i] = all_points.index(key[i].tolist())
            indices.append(purmutation_index)
        sorted_indices = []
        for index in indices:
            index.sort()
            sorted_indices.append(index)
        return min(sorted_indices)
        

    def _index_to_points(self, ticker,all_points):
        '''Converts the list of indices back to a list of points'''
        points = [0,]*len(ticker)
        for i in range(len(ticker)):
            points[i] = all_points[ticker[i]]    
        return points
        
        
    def percent_fractional_set(self,max_degree):
        self.compute_dimension_table()
        self.open_db()
        c = self.conn.cursor()
        entry = str('N/A')
        c.execute('SELECT Percent,Degree FROM MMSet WHERE Percent !=?',(entry,))
        percents = c.fetchall()
        self.close_db()
        elements = []
        for i in range(len(percents)-1,0,-1):
            if percents[i][1] > max_degree:
                percents.remove(percents[i])     
        print len(percents),'Possibly Fractional Base Sets'
        print ' '
        elements = list(set(percents))
        elements.sort()
        if len(elements) >= 2:
            elements.append(elements[1])
            elements.remove(elements[1])
        count = []
        for i in range(len(elements)):
            count.append(percents.count(elements[i]))
            print elements[i][0], count[i]
        print ' '
        
    
    def percent_non_sos(self,max_degree):
        self.compute_dimension_table()
        self.open_db()
        c = self.conn.cursor()
        entry = str('N/A')
        c.execute('SELECT `MMSet Size`,`Max Set Size`,Orbits,Degree FROM MMSet WHERE Percent !=?',(entry,))
        set_sizes = c.fetchall()
        self.close_db()
        sum_max = 0
        sum_mms = 0
        for i in range(len(set_sizes)):
            if set_sizes[i][3] <= max_degree:
                sum_mms = sum_mms + set_sizes[i][0] * set_sizes[i][2]
                sum_max = sum_max + set_sizes[i][1] * set_sizes[i][2]
        return float(sum_mms*100)/sum_max
        
        
    def delete_table(self):
        self.close_db()
        os.remove(self.path)
        
        
def percent_non_sos_vs_degree(dim, max_degree):
    bars = []
    db = MMSet_DB()
    db.create_new_table(dim,max_degree)
    db.compute_dimension_table()
    for i in range(4,max_degree+1,2):
        bars.append(db.percent_non_sos(i))
    print bars
    return bar_chart(bars)
    
    
def percent_non_sos_vs_dim(max_dim,degree):
    bars = []
    for i in range(2,max_dim+1):
        db = MMSet_DB()
        db.create_new_table(i,degree)
        db.compute_dimension_table()
        bars.append(db.percent_non_sos())
    print bars
    return bar_chart(bars)