data {
  int<lower=1> N;
  int<lower=1> p;
  int<lower=1> d1;
  int<lower=1> d2;

  int y[N,N,p];
  real lambda1;
  real lambda2;
  real lambda3;
}
parameters {
  matrix[N,d1] U;
  matrix[p,d2] V;
  real eta[d1,d1,d2];

  real<lower=0> tau[d1];
  real<lower=0> phi1;
  real<lower=0> phi2;

}
model {

    matrix[N*N,d2] UDU;
    matrix[N*N,p] UDUV;

    matrix[d1,d1]  U2;
    matrix[d2,d2]  V2;

    matrix[d1,d1] eta1;


    //tensor product
    for(l in 1:d2){

      for(i in 1:d1){
        target +=  normal_lpdf(to_vector(eta[i,:,l]) | 0, sqrt(tau[i]));
        eta1[i,i] =eta[i,i,l];
        for(j in 1:(i-1)){
          eta1[i,j] = eta[i,j,l];
          eta1[j,i] = eta[i,j,l];
        }
      }
      UDU[:,l] = to_vector(U * eta1 * U');
    }
    UDUV = UDU * V';

    //bernoulli
    for(l in 1:p){
      for(i in 1:N){
        for(j in 1:(i-1)){
          target += bernoulli_logit_lpmf(y[i,j,l] | UDUV[(i-1)*N+j,l]);
        }
      }
    }

    //variance for the core
    for(i in 1:d1){
        target +=  gamma_lpdf( 1.0/tau[i] | 2, 1);
    }

    //variance for the factors
    target +=  normal_lpdf( to_vector(U) | 0, sqrt(phi1));
    target +=  gamma_lpdf( 1.0/phi1 | 2,1);
    target +=  normal_lpdf( to_vector(V) | 0, sqrt(phi2));
    target +=  gamma_lpdf( 1.0/phi2 | 2,1);

    //constrain orthonormality in U
    U2 = U' * U - diag_matrix(rep_vector(1.0, d1));
    target += - lambda2* trace( U2 *U2);

    //constrain orthonormality in V
    V2 = V' * V - diag_matrix(rep_vector(1.0, d2));
    target += - lambda2* trace( V2 *V2);
  
    //constrain first element in each factor to be positive
    for(m in 1:d1){
      if( U[1,m] < 0){
        target +=   -lambda3 * (-U[1,m]);
      }
    }

    //constrain order of tau
    for(m in 1:(d1-1)){
      if( tau[m] < tau[m+1]){
        target +=   -lambda1 *( tau[m+1] - tau[m]);
      }
    }


}