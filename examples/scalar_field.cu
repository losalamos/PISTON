/*
 * scalar_field.cu
 *
 *  Created on: Aug 23, 2011
 *      Author: ollie
 */

#include <typeinfo>
#include <thrust/host_vector.h>

#include <piston/implicit_function.h>
#include <piston/image3d.h>

static const int GRID_SIZE = 3;

template <typename IndexType, typename ValueType>
struct sphere : piston::implicit_function3d<IndexType, ValueType>
{
    typedef piston::implicit_function3d<IndexType, ValueType> Parent;
    typedef typename Parent::InputType InputType;

    const IndexType x_o;
    const IndexType y_o;
    const IndexType z_o;
    const IndexType radius;

    sphere(IndexType x, IndexType y, IndexType z, IndexType radius) :
	x_o(x), y_o(y), z_o(z), radius(radius) {}

    __host__ __device__
    ValueType operator()(InputType pos) const {
	const IndexType x = thrust::get<0>(pos);
	const IndexType y = thrust::get<1>(pos);
	const IndexType z = thrust::get<2>(pos);
	const IndexType xx = x - x_o;
	const IndexType yy = y - y_o;
	const IndexType zz = z - z_o;
	return (xx*xx + yy*yy + zz*zz - radius*radius);
    }
};

template <typename IndexType, typename ValueType>
struct sfield : public piston::image3d<IndexType, ValueType, thrust::host_space_tag>
{
    typedef piston::image3d<IndexType, ValueType, thrust::host_space_tag> Parent;

    typedef thrust::transform_iterator<sphere<IndexType, ValueType>,
				       typename Parent::GridCoordinatesIterator> PointDataIterator;
    PointDataIterator iter;

    sfield(int xdim, int ydim, int zdim) :
	Parent(xdim, ydim, zdim),
	iter(this->grid_coordinates_iterator,
	     sphere<IndexType, ValueType>(0, 0, 0, 1)){}

    PointDataIterator point_data_begin() {
	return iter;
    }

    PointDataIterator point_data_end() {
	return iter+this->NPoints;
    }
};

template <typename IndexType, typename ValueType>
struct sfield_gb : public piston::image3d<IndexType, ValueType, thrust::host_space_tag>
{
    typedef piston::image3d<IndexType, ValueType, thrust::host_space_tag> Parent;

    typedef thrust::host_vector<thrust::tuple<IndexType, IndexType, IndexType> > GridCoordinatesContainer;
    GridCoordinatesContainer grid_coordinates_vector;
    typedef typename GridCoordinatesContainer::iterator GridCoordinatesIterator;
    GridCoordinatesIterator grid_coordinates_iterator;

    typedef thrust::transform_iterator<sphere<IndexType, ValueType>,
				       GridCoordinatesIterator> PointDataIterator;
    PointDataIterator iter;

    sfield_gb(int xdim, int ydim, int zdim) :
	Parent(xdim, ydim, zdim),
	grid_coordinates_vector(Parent::grid_coordinates_begin(), Parent::grid_coordinates_end()),
	grid_coordinates_iterator(grid_coordinates_vector.begin()),
	iter(this->grid_coordinates_iterator,
	     sphere<IndexType, ValueType>(0, 0, 0, 1)){}

    GridCoordinatesIterator grid_coordinates_begin() {
	return grid_coordinates_iterator;
    }
    GridCoordinatesIterator grid_coordinates_end() {
	return grid_coordinates_iterator+this->NPoints;
    }

    PointDataIterator point_data_begin() {
	return iter;
    }

    PointDataIterator point_data_end() {
	return iter+this->NPoints;
    }
};

template <typename IndexType, typename ValueType>
struct sfield_gbpb : public piston::image3d<IndexType, ValueType, thrust::host_space_tag>
{
    typedef piston::image3d<IndexType, ValueType, thrust::host_space_tag> Parent;

    typedef thrust::host_vector<thrust::tuple<IndexType, IndexType, IndexType> > GridCoordinatesContainer;
    GridCoordinatesContainer grid_coordinates_vector;
    typedef typename GridCoordinatesContainer::iterator GridCoordinatesIterator;
    GridCoordinatesIterator grid_coordinates_iterator;

    typedef thrust::host_vector<ValueType> PointDataContainer;
    PointDataContainer point_data_vector;
    typedef typename PointDataContainer::iterator PointDataIterator;
    PointDataIterator point_data_iterator;

    sfield_gbpb(int xdim, int ydim, int zdim) :
	Parent(xdim, ydim, zdim),
	grid_coordinates_vector(Parent::grid_coordinates_begin(), Parent::grid_coordinates_end()),
	grid_coordinates_iterator(grid_coordinates_vector.begin()),
	point_data_vector(thrust::make_transform_iterator(grid_coordinates_iterator, sphere<IndexType, ValueType>(0, 0, 0, 1)),
	                  thrust::make_transform_iterator(grid_coordinates_iterator, sphere<IndexType, ValueType>(0, 0, 0, 1))+this->NPoints),
	point_data_iterator(point_data_vector.begin()) {}

    GridCoordinatesIterator grid_coordinates_begin() {
	return grid_coordinates_iterator;
    }
    GridCoordinatesIterator grid_coordinates_end() {
	return grid_coordinates_iterator+this->NPoints;
    }

    PointDataIterator point_data_begin() {
	return point_data_iterator;
    }

    PointDataIterator point_data_end() {
	return point_data_iterator+this->NPoints;
    }
};

struct print_coordinate : public thrust::unary_function<thrust::tuple<int , int, int>, void>
{
    void operator()(thrust::tuple<int, int, int> pos) const {
	std::cout << "("  << thrust::get<0>(pos)
		  << ", " << thrust::get<1>(pos)
		  << ", " << thrust::get<2>(pos)
		  << ")" << std::endl;
    }
};

int main()
{
    // the basic 3D scalar field, grid coordinates and scalar values are computed on the fly
    sfield<int, int> scalar_field(GRID_SIZE, GRID_SIZE, GRID_SIZE);
    std::cout << typeid(scalar_field.grid_coordinates_begin()).name() << std::endl;
    thrust::for_each(scalar_field.grid_coordinates_begin(), scalar_field.grid_coordinates_end(), print_coordinate());
    std::cout << typeid(scalar_field.point_data_begin()).name() << std::endl;
    thrust::copy(scalar_field.point_data_begin(), scalar_field.point_data_end(), std::ostream_iterator<int>(std::cout, " "));
    std::cout << std::endl;

    sfield_gb<int, int> scalar_field_gb(GRID_SIZE, GRID_SIZE, GRID_SIZE);
    std::cout << typeid(scalar_field_gb.grid_coordinates_begin()).name() << std::endl;
    thrust::for_each(scalar_field_gb.grid_coordinates_begin(), scalar_field_gb.grid_coordinates_end(), print_coordinate());
    std::cout << typeid(scalar_field_gb.point_data_begin()).name() << std::endl;
    thrust::copy(scalar_field_gb.point_data_begin(), scalar_field_gb.point_data_end(), std::ostream_iterator<int>(std::cout, " "));
    std::cout << std::endl;

    sfield_gbpb<int, int> scalar_field_gbpb(GRID_SIZE, GRID_SIZE, GRID_SIZE);
    std::cout << typeid(scalar_field_gbpb.grid_coordinates_begin()).name() << std::endl;
    thrust::for_each(scalar_field_gbpb.grid_coordinates_begin(), scalar_field_gbpb.grid_coordinates_end(), print_coordinate());
    std::cout << typeid(scalar_field_gbpb.point_data_begin()).name() << std::endl;
    thrust::copy(scalar_field_gbpb.point_data_begin(), scalar_field_gbpb.point_data_end(), std::ostream_iterator<int>(std::cout, " "));
    std::cout << std::endl;
    return 0;
}
