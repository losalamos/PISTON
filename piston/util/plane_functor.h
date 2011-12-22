/*
Copyright (c) 2011, Los Alamos National Security, LLC
All rights reserved.
Copyright 2011. Los Alamos National Security, LLC. This software was produced under U.S. Government contract DE-AC52-06NA25396 for Los Alamos National Laboratory (LANL),
which is operated by Los Alamos National Security, LLC for the U.S. Department of Energy. The U.S. Government has rights to use, reproduce, and distribute this software.

NEITHER THE GOVERNMENT NOR LOS ALAMOS NATIONAL SECURITY, LLC MAKES ANY WARRANTY, EXPRESS OR IMPLIED, OR ASSUMES ANY LIABILITY FOR THE USE OF THIS SOFTWARE.

If software is modified to produce derivative works, such modified software should be clearly marked, so as not to confuse it with the version available from LANL.

Additionally, redistribution and use in source and binary forms, with or without modification, are permitted provided that the following conditions are met:
·         Redistributions of source code must retain the above copyright notice, this list of conditions and the following disclaimer.
·         Redistributions in binary form must reproduce the above copyright notice, this list of conditions and the following disclaimer in the documentation and/or other
          materials provided with the distribution.
·         Neither the name of Los Alamos National Security, LLC, Los Alamos National Laboratory, LANL, the U.S. Government, nor the names of its contributors may be used
          to endorse or promote products derived from this software without specific prior written permission.

THIS SOFTWARE IS PROVIDED BY LOS ALAMOS NATIONAL SECURITY, LLC AND CONTRIBUTORS "AS IS" AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED
WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE DISCLAIMED. IN NO EVENT SHALL LOS ALAMOS NATIONAL SECURITY, LLC OR CONTRIBUTORS BE LIABLE FOR ANY
DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA,
OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE)
ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
*/

#ifndef PLANE_FUNCTOR_H_
#define PLANE_FUNCTOR_H_

#include <piston/implicit_function.h>

namespace piston
{

template <typename IndexType, typename ValueType>
struct plane_functor : public piston::implicit_function3d<IndexType, ValueType>
{
    typedef piston::implicit_function3d<IndexType, ValueType> Parent;
    typedef typename Parent::InputType InputType;

    int pointsPerLayer, xDim, yDim, zDim;
    const float3 origin;
    const float3 normal;

    plane_functor(float3 origin, float3 normal, int xDim, int yDim, int zDim) :
	origin(origin), normal(normal), xDim(xDim), yDim(yDim), zDim(zDim), pointsPerLayer(yDim*xDim) {}

    __host__ __device__
    float operator()(InputType pos) const {
    	const IndexType xc = thrust::get<0>(pos);
    	const IndexType yc = thrust::get<1>(pos);
    	const IndexType zc = thrust::get<2>(pos);

    	// scale and shift such that x, y, z <- [-1,1]
    	const float x = 2*static_cast<float>(xc)/(xDim-1) - 1;
    	const float y = 2*static_cast<float>(yc)/(yDim-1) - 1;
    	const float z = 2*static_cast<float>(zc)/(zDim-1) - 1;

        return dot(make_float3(x, y, z) - origin, normal);
    }
};

}

#endif /* PLANE_FUNCTOR_H_ */